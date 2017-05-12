#!/usr/bin/perl
# vim: filetype=perl ts=2 sw=2 expandtab

# Test connection queuing.  Set the max active connection to be really
# small (one in all), and then try to allocate two connections.  The
# second should queue.

use warnings;
use strict;
use lib qw(./mylib ../mylib);
use Test::More tests => 9;
use Errno qw(ECONNREFUSED ETIMEDOUT);

sub POE::Kernel::ASSERT_DEFAULT () { 1 }

use POE;
use POE::Component::Client::Keepalive;
use POE::Component::Resolver;
use Socket qw(AF_INET);

use TestServer;

diag("This test may take a long time if your firewall blackholes connections.");

my $server_port  = TestServer->spawn(0);
my $unknown_port = $server_port + 1;    # Kludge. Fingers crossed.

POE::Session->create(
  inline_states => {
    _child          => sub { },
    _start          => \&start,
    _stop           => sub { },
    got_error       => \&got_error,
    got_first_conn  => \&got_first_conn,
    got_third_conn  => \&got_third_conn,
    got_fourth_conn => \&got_fourth_conn,
    got_timeout     => \&got_timeout,
    test_max_queue  => \&test_max_queue,
  }
);

sub start {
  my $heap = $_[HEAP];

  $heap->{cm} = POE::Component::Client::Keepalive->new(
    max_open => 1,
    resolver => POE::Component::Resolver->new(af_order => [ AF_INET ]),
  );

  # Count the number of times test_max_queue is called.  When that's
  # 2, we actually do the test.

  $heap->{test_max_queue} = 0;

  # Make two identical tests.  They're both queued because the free
  # pool is empty at this point.

  {
    $heap->{cm}->allocate(
      scheme  => "http",
      addr    => "127.0.0.1",
      port    => $server_port,
      event   => "got_first_conn",
      context => "first",
    );
  }

  {
    $heap->{cm}->allocate(
      scheme  => "http",
      addr    => "127.0.0.1",
      port    => $server_port,
      event   => "got_first_conn",
      context => "second",
    );
  }
}

sub got_first_conn {
  my ($kernel, $heap, $stuff) = @_[KERNEL, HEAP, ARG0];

  my $conn = delete $stuff->{connection};
  my $which = $stuff->{context};
  ok(defined($conn), "$which connection honored asynchronously");
  if ($which eq 'first') {
    ok(not (defined ($stuff->{from_cache})), "$which not from cache");
  } else {
    ok(defined ($stuff->{from_cache}), "$which from cache");
  }

  $conn = undef;

  $kernel->yield("test_max_queue");
}

sub got_third_conn {
  my ($kernel, $heap, $stuff) = @_[KERNEL, HEAP, ARG0];

  my $conn = $stuff->{connection};
  my $which = $stuff->{context};
  ok(
    defined($stuff->{from_cache}),
    "$which connection request honored from pool"
  );

  $conn = undef;
}

# We need a free connection pool of 2 or more for this next test.  We
# want to allocate one of them, and then attempt to allocate a
# different connection.

sub test_max_queue {
  my ($kernel, $heap) = @_[KERNEL, HEAP];

  $heap->{test_max_queue}++;
  return unless $heap->{test_max_queue} == 2;

  $heap->{cm}->allocate(
    scheme  => "http",
    addr    => "127.0.0.1",
    port    => $server_port,
    event   => "got_third_conn",
    context => "third",
  );

  $heap->{cm}->allocate(
    scheme  => "http",
    addr    => "127.0.0.1",
    port    => $unknown_port,
    event   => "got_fourth_conn",
    context => "fourth",
  );
}

# This connection should fail, actually.

sub got_fourth_conn {
  my ($kernel, $heap, $stuff) = @_[KERNEL, HEAP, ARG0];

  my $conn = $stuff->{connection};
  ok(!defined($conn), "fourth connection failed (as it should)");

  ok($stuff->{function} eq "connect", "connection failed in connect");
  ok(
    ($stuff->{error_num} == ECONNREFUSED) || ($stuff->{error_num} == ETIMEDOUT),
    "connection error ECONNREFUSED"
  );

  my $lc_str = lc $stuff->{error_str};

  $! = ECONNREFUSED;
  my @wanted = ( lc "$!" );
  $! = ETIMEDOUT;
  push @wanted, lc "$!";
  push @wanted, "unknown error" if $^O eq "MSWin32";

  ok(
    (grep { $lc_str eq $_ } @wanted),
    "error string: wanted(connection refused) got($lc_str)"
  );

  # Shut things down.
  TestServer->shutdown();
  $heap->{cm}->shutdown();
}

POE::Kernel->run();
exit;
