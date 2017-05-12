#!/usr/bin/perl
# vim: filetype=perl

# Test connection queuing.  Set the per-connection queue to be really
# small (one in all), and then try to allocate two connections.  The
# second should queue.

use warnings;
use strict;
use lib qw(./mylib ../mylib);
use Test::More tests => 8;

sub POE::Kernel::ASSERT_DEFAULT () { 1 }

use POE;
use POE::Component::Client::Keepalive;
use POE::Component::Resolver;
use Socket qw(AF_INET);

use TestServer;
my $server_port = TestServer->spawn(0);

POE::Session->create(
  inline_states => {
    _child          => sub { },
    _start          => \&start,
    _stop           => sub { },
    got_error       => \&got_error,
    got_first_conn  => \&got_first_conn,
    got_fourth_conn => \&got_fourth_conn,
    got_third_conn => \&got_third_conn,
    got_timeout     => \&got_timeout,
    test_pool_alive => \&test_pool_alive,
  }
);

sub start {
  my $heap = $_[HEAP];

  $heap->{cm} = POE::Component::Client::Keepalive->new(
    max_per_host => 1,
    resolver     => POE::Component::Resolver->new(af_order => [ AF_INET ]),
  );

  # Count the number of times test_pool_alive is called.  When that's
  # 2, we actually do the test.

  $heap->{test_pool_alive} = 0;

  # Make two identical tests.  They're both queued because the free
  # pool is empty at this point.

  {
    $heap->{cm}->allocate(
      scheme  => "http",
      addr    => "localhost",
      port    => $server_port,
      event   => "got_first_conn",
      context => "first",
    );
  }

  {
    $heap->{cm}->allocate(
      scheme  => "http",
      addr    => "localhost",
      port    => $server_port,
      event   => "got_first_conn",
      context => "second",
    );
  }
}

sub got_first_conn {
  my ($kernel, $heap, $stuff) = @_[KERNEL, HEAP, ARG0];

  my $conn = $stuff->{connection};
  my $which = $stuff->{context};

  if (defined $conn) {
    pass "$which request honored asynchronously";
  }
  else {
    fail(
      "$which request $stuff->{function} error $stuff->{error_num}: " .
      $stuff->{error_str}
    );
  }

  if ($which eq 'first') {
    ok(not (defined ($stuff->{from_cache})), "$which not from cache");
  } else {
    is($stuff->{from_cache}, 'deferred', "$which deferred from cache");
  }

  $kernel->yield("test_pool_alive");
}

sub got_third_conn {
  my ($kernel, $heap, $stuff) = @_[KERNEL, HEAP, ARG0];

  my $conn = $stuff->{connection};
  my $which = $stuff->{context};

  if (defined $conn) {
    pass "$which request honored asynchronously";
  }
  else {
    fail(
      "$which request $stuff->{function} error $stuff->{error_num}: " .
      $stuff->{error_str}
    );
  }

  is($stuff->{from_cache}, 'immediate', "$which connection request honored from pool immediately");
}

# We need a free connection pool of 2 or more for this next test.  We
# want to allocate and free one of them to make sure the pool is not
# destroyed.  Yay, Devel::Cover, for making me actually do this.

sub test_pool_alive {
  my ($kernel, $heap) = @_[KERNEL, HEAP];

  $heap->{test_pool_alive}++;
  return unless $heap->{test_pool_alive} == 2;

  $heap->{cm}->allocate(
    scheme  => "http",
    addr    => "localhost",
    port    => $server_port,
    event   => "got_third_conn",
    context => "third",
  );

  $heap->{cm}->allocate(
    scheme  => "http",
    addr    => "localhost",
    port    => $server_port,
    event   => "got_fourth_conn",
    context => "fourth",
  );
}

sub got_fourth_conn {
  my ($kernel, $heap, $stuff) = @_[KERNEL, HEAP, ARG0];

  my $conn = delete $stuff->{connection};

  if (defined $conn) {
    pass "fourth request established asynchronously";
  }
  else {
    fail(
      "fourth request $stuff->{function} error $stuff->{error_num}: " .
      $stuff->{error_str}
    );
  }

  is ($stuff->{from_cache}, 'deferred', "connection from pool");

  $conn = undef;

  TestServer->shutdown();
  $heap->{cm}->shutdown();
}

POE::Kernel->run();
exit;
