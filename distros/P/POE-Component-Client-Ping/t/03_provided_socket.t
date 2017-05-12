#!/usr/bin/perl -w
# vim: filetype=perl ts=2 sw=2 expandtab

use strict;

BEGIN {
  $| = 1;
  if ($> and ($^O ne 'VMS')) {
    print "1..0 # skipped: ICMP ping requires root privilege\n";
    exit 0;
  }
};

sub POE::Kernel::ASSERT_DEFAULT () { 1 }
use POE qw(Component::Client::Ping);
use Test::More tests => 2;

sub PING_TIMEOUT () { 5 }; # seconds between pings
sub PING_COUNT   () { 1 }; # ping repetitions
sub DEBUG        () { 0 }; # display more information

#------------------------------------------------------------------------------
# A bunch of addresses to ping.

my @addresses = qw(
  127.0.0.1 209.34.66.60 216.127.84.31 216.132.181.250 216.132.181.251
  64.106.159.160 64.127.105.9 64.235.246.143 64.38.255.150
  66.207.163.5 66.33.204.143
);

#------------------------------------------------------------------------------
# This session uses the ping component to resolve things.

sub client_start {
  my ($kernel, $session, $heap) = @_[KERNEL, SESSION, HEAP];

  DEBUG and warn($session->ID, ": starting pinger client session...\n");

  # Set up recording.
  $heap->{requests}    = 0;
  $heap->{answers}     = 0;
  $heap->{dones}       = 0;
  $heap->{ping_counts} = { };

  # Start pinging.
  foreach my $address (@addresses) {
    $heap->{ping_counts}->{$address} = 0;
    $kernel->call( $session, ping => $address );
  }
}

sub client_send_ping {
  my ($kernel, $session, $heap, $address) = @_[KERNEL, SESSION, HEAP, ARG0];

  DEBUG and warn( $session->ID, ": pinging $address...\n" );

  $heap->{requests}++;
  $heap->{ping_counts}->{$address}++;
  $kernel->post(
    'pinger',     # Post the request to the 'pinger'.
    'ping',       # Ask it to 'ping' an address.
    'pong',       # Have it post an answer to my 'pong' state.
    $address,     # This is the address we want it to ping.
    PING_TIMEOUT  # This is the optional time to wait.
  );
}

sub client_got_pong {
  my ($kernel, $session, $heap, $request_packet, $response_packet) =
    @_[KERNEL, SESSION, HEAP, ARG0, ARG1];

  my ($request_address, $request_timeout, $request_time) = @{$request_packet};
  my (
    $response_address, $roundtrip_time, $reply_time, $reply_ttl
  ) = @{$response_packet};

  if (defined $response_address) {
    DEBUG and warn(
      sprintf(
        "%d: ping to %-15.15s at %10d. " .
        "pong from %-15.15s in %6.3f s (ttl %3d)\n",
        $session->ID,
        $request_address, $request_time,
        $response_address, $roundtrip_time, $reply_ttl,
      )
    );

    $heap->{answers}++ if $roundtrip_time <= $request_timeout;
    $heap->{bad_ttl}++ if (
      $reply_ttl !~ /^\d+$/ or
      $reply_ttl < 0 or
      $reply_ttl > 255
    );
  }
  else {
    DEBUG and warn( $session->ID, ": time's up for $request_address...\n" );

    $kernel->yield(ping => $request_address) if (
      $heap->{ping_counts}->{$request_address} < PING_COUNT
    );

    $heap->{dones}++;
  }
}

sub client_stop {
  my ($session, $heap) = @_[SESSION, HEAP];
  DEBUG and warn( $session->ID, ": pinger client session stopped...\n" );

  ok(
    (
      $heap->{requests} == $heap->{dones}
      && $heap->{answers}
      && !$heap->{bad_ttl}
    ),
    "pinger client session got responses"
  );
}

#------------------------------------------------------------------------------

# Create a raw socket externally for the component to use.

use Symbol qw(gensym);
use Socket;

my $protocol = (getprotobyname('icmp'))[2]
  or die "can't get icmp protocol by name: $!";

my $socket = gensym();
socket($socket, PF_INET, SOCK_RAW, $protocol)
  or die "can't create icmp socket: $!";

# Create a pinger component.
POE::Component::Client::Ping->spawn(
  Alias   => 'pinger',     # This is the name it'll be known by.
  Timeout => PING_TIMEOUT, # This is how long it waits for echo replies.
  Socket => $socket,
);

# Create two sessions that will use the pinger.  This tests
# concurrency against the same addresses.
for (my $session_index = 0; $session_index < 2; $session_index++) {
  POE::Session->create(
    inline_states => {
      _start => \&client_start,
      _stop  => \&client_stop,
      pong   => \&client_got_pong,
      ping   => \&client_send_ping,
    }
  );
}

# Run it all until done.
POE::Kernel->run();

exit;
