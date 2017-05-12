#!/usr/bin/perl -w
# vim: ts=2 sw=2 expandtab

# Exercises Client and Server TCP components, which exercise
# SocketFactory in AF_INET6 mode.

use strict;
use lib qw(./mylib ../mylib);

BEGIN {
  # under perl-5.6.2 the warning "leaks" from the eval, while newer versions don't...
  # it's due to Exporter.pm behaving differently, so we have to shut it up
  no warnings 'redefine';
  require Carp;
  local *Carp::carp = sub { die @_ };
  eval { require Socket; Socket->import('AF_INET6') };
  if ($@) {
    eval { require Socket6; Socket6->import('AF_INET6') };
    if ($@) {
      print "1..0 # Skip Cannot find AF_INET6 support in Socket or Socket6.\n";
      CORE::exit();
    }
  }
}

# Second BEGIN block so that AF_INET6 is defined before this code is
# compiled.

BEGIN {
  my $error;

  eval 'use Socket::GetAddrInfo qw(:newapi getaddrinfo getnameinfo NI_NUMERICHOST NI_NUMERICSERV)';
  if ($@) {
    $error = "Socket::GetAddrInfo is needed for IPv6 tests";
  }
  elsif ($^O eq "cygwin") {
    $error = (
      "IPv6 isn't available on Cygwin, even with Socket::GetAddrInfo installed"
    );
  }
  else {
    my $addr;
    eval {
      my ($error, @addr) = getaddrinfo(
        "localhost", 80, { family => AF_INET6 }
      );
      $addr = $addr[0]{addr} if @addr;
    };
    if ($@) {
      $error = "error resolving localhost for IPv6: $@";
    }
    elsif (!defined $addr) {
      $error = "IPv6 tests require a configured IPv6 localhost address";
    }
    elsif (!-f 'run_network_tests') {
      $error = "Network access (and permission) required to run this test";
    }
  }

  # Not Test::More, because I'm pretty sure skip_all calls Perl's
  # regular exit().
  if ($error) {
    print "1..0 # Skip $error\n";
    CORE::exit();
  }
}

sub POE::Kernel::ASSERT_DEFAULT () { 1 }

BEGIN {
  package
  POE::Kernel;
  use constant TRACE_DEFAULT => exists($INC{'Devel/Cover.pm'});
}

use POE qw( Component::Client::TCP Component::Server::TCP );

my $tcp_server_port;

# Congratulations! We made it this far!
use Test::More tests => 3;

diag( "This test may hang if your firewall blocks IPv6" );
diag( "packets across your localhost interface." );

###############################################################################
# Start the TCP server.

POE::Component::Server::TCP->new(
  Port               => 0,
  Address            => '::1',
  Domain             => AF_INET6,
  Alias              => 'server',
  ClientConnected    => \&server_got_connect,
  ClientInput        => \&server_got_input,
  ClientFlushed      => \&server_got_flush,
  ClientDisconnected => \&server_got_disconnect,
  Error              => \&server_got_error,
  ClientError        => sub { }, # Hush a warning.
  Started            => sub {
    eval {
      my $socket_name = $_[HEAP]{listener}->getsockname();
      (my ($err, $host), $tcp_server_port) = getnameinfo(
        $socket_name, NI_NUMERICHOST | NI_NUMERICSERV
      );
    };
    if (!$tcp_server_port || $@) {
      $tcp_server_port = undef;
      SKIP: {
        my $errstr = @$ || 'server port undefined';
        skip "AF_INET6 probably not supported or configured ($errstr)", 2;
      }
    }
  },
);

sub server_got_connect {
  my $heap = $_[HEAP];
  $heap->{server_test_one} = 1;
  $heap->{flush_count} = 0;
  $heap->{put_count}   = 0;
}

sub server_got_input {
  my ($heap, $line) = @_[HEAP, ARG0];
  $line =~ tr/a-zA-Z/n-za-mN-ZA-M/; # rot13
  $heap->{client}->put($line);
  $heap->{put_count}++;
}

sub server_got_flush {
  $_[HEAP]->{flush_count}++;
}

sub server_got_disconnect {
  my $heap = $_[HEAP];
  ok(
    $heap->{put_count} == $heap->{flush_count},
    "server put_count matches flush_count"
  );
}

sub server_got_error {
  my ($syscall, $errno, $error) = @_[ARG0..ARG2];
  SKIP: {
    skip "AF_INET6 probably not supported ($syscall error $errno: $error)", 1
  }
}

###############################################################################
# Start the TCP client.

if ($tcp_server_port) {
  POE::Component::Client::TCP->new(
    RemoteAddress => '::1',
    RemotePort    => $tcp_server_port,
    Domain        => AF_INET6,
    BindAddress   => '::1',
    Connected     => \&client_got_connect,
    ServerInput   => \&client_got_input,
    ServerFlushed => \&client_got_flush,
    Disconnected  => \&client_got_disconnect,
    ConnectError  => \&client_got_connect_error,
  );
}

sub client_got_connect {
  my $heap = $_[HEAP];
  $heap->{flush_count} = 0;
  $heap->{put_count}   = 1;
  $heap->{server}->put( '1: this is a test' );
}

sub client_got_input {
  my ($kernel, $heap, $line) = @_[KERNEL, HEAP, ARG0];

  if ($line =~ s/^1: //) {
    $heap->{put_count}++;
    $heap->{server}->put( '2: ' . $line );
  }
  elsif ($line =~ s/^2: //) {
    ok(
      $line eq "this is a test",
      "received input"
    );
    $kernel->post(server => "shutdown");
    $kernel->yield("shutdown");
  }
}

sub client_got_flush {
  $_[HEAP]->{flush_count}++;
}

sub client_got_disconnect {
  my $heap = $_[HEAP];
  ok(
    $heap->{put_count} == $heap->{flush_count},
    "client put_count matches flush_count"
  );
}

sub client_got_connect_error {
  my ($syscall, $errno, $error) = @_[ARG0..ARG2];
  SKIP: {
    skip "AF_INET6 probably not supported ($syscall error $errno: $error)", 2;
  }
}

### main loop

POE::Kernel->run();

1;
