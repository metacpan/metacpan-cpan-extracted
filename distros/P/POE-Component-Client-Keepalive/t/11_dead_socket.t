#!/usr/bin/perl

# Test connection queuing.  Set the per-connection queue to be really
# small (one in all), and then try to allocate two connections.  The
# second should queue.

use warnings;
use strict;
use lib qw(./mylib ../mylib);
use Test::More tests => 7;

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
    cleanup1        => \&cleanup1,
    cleanup         => \&cleanup,
    error      => \&error,
    input      => \&input,
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
  ok(defined($conn), "$which connection established asynchronously");
  if ($which eq 'first') {
    ok(not (defined ($stuff->{from_cache})), "$which not from cache");
    my $wheel = $conn->start(
      ErrorEvent => 'error',
  InputEvent => 'cleanup1',
      );
    $heap->{conn} = $conn;
    TestServer->send_something;
  } else {
    ok(not (defined ($stuff->{from_cache})), "$which not from cache");
    my $wheel = $conn->start(
      ErrorEvent => 'error',
  InputEvent => 'input',
      );
    TestServer->send_something;
    $heap->{conn} = $conn;
    $kernel->delay_add ('cleanup', 1);
  }
}

sub cleanup1 {
  is ($_[ARG1], $_[HEAP]->{conn}->wheel->ID, "input for correct wheel");
  $_[HEAP]->{wheelid} = $_[ARG1];
  TestServer->shutdown_clients;
  delete $_[HEAP]->{conn};
}

sub cleanup {
  delete $_[HEAP]->{conn};
  TestServer->shutdown;
}

sub error {
  my $heap = $_[HEAP];
  is ($heap->{wheelid}, $heap->{conn}->wheel->ID, "eof arrives at same wheel");
  delete $_[HEAP]->{wheelid};
  $heap->{conn}->wheel->shutdown_input;
  $heap->{conn}->wheel->shutdown_output;
  delete $heap->{conn};
}

sub input {
  $_[HEAP]->{wheelid} = $_[ARG1];
  ok (1, "input arrives from new socket");
  TestServer->shutdown_clients;
}
POE::Kernel->run();
exit;
