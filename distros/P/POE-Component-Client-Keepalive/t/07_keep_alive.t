#!/usr/bin/perl

# Test keepalive.  Allocates a connection, frees it, waits for the
# keep-alive timeout, allocates an identical connection.  The second
# allocation should return a different connection.

use warnings;
use strict;
use lib qw(./mylib ../mylib);
use Test::More tests => 6;

sub POE::Kernel::ASSERT_DEFAULT () { 1 }

use POE;
use POE::Component::Client::Keepalive;
use POE::Component::Resolver;
use Socket qw(AF_INET);

use TestServer;
my $server_port = TestServer->spawn(0);

POE::Session->create(
  inline_states => {
    _child            => sub { },
    _start            => \&start,
    _stop             => sub { },
    got_conn          => \&got_conn,
    got_first_conn    => \&got_first_conn,
    kept_alive        => \&keepalive_over,
    second_kept_alive => \&second_kept_alive,
  }
);

sub start {
  my $heap = $_[HEAP];

  $heap->{others} = 0;

  $heap->{cm} = POE::Component::Client::Keepalive->new(
    keep_alive => 1,
    resolver   => POE::Component::Resolver->new(af_order => [ AF_INET ]),
  );

  $heap->{cm}->allocate(
    scheme  => "http",
    addr    => "localhost",
    port    => $server_port,
    event   => "got_first_conn",
    context => "first",
  );

}

sub got_first_conn {
  my ($kernel, $heap, $stuff) = @_[KERNEL, HEAP, ARG0];

  my $conn = $stuff->{connection};
  ok(!defined($stuff->{from_cache}), "first connection request deferred");
  ok(defined($conn), "first request honored asynchronously");

  $kernel->delay(kept_alive => 2);
}

sub keepalive_over {
  my $heap = $_[HEAP];

  # The second and third requests should be deferred.  The first
  # connection won't be reused because it should have been reaped by
  # the keep-alive timer.

  $heap->{cm}->allocate(
    scheme  => "http",
    addr    => "localhost",
    port    => $server_port,
    event   => "got_conn",
    context => "second",
  );

  $heap->{cm}->allocate(
    scheme  => "http",
    addr    => "localhost",
    port    => $server_port,
    event   => "got_conn",
    context => "third",
  );
}

sub got_conn {
  my ($kernel, $heap, $stuff) = @_[KERNEL, HEAP, ARG0];

  my $conn  = $stuff->{connection};
  my $which = $stuff->{context};
  ok(defined($conn), "$which request honored asynchronously");
  ok(!defined ($stuff->{from_cache}), "$which uses a new connection");

  if (++$heap->{others} == 2) {
    $kernel->delay(second_kept_alive => 2);
  }
}

sub second_kept_alive {
  TestServer->shutdown();
  $_[HEAP]->{cm}->shutdown();
}

POE::Kernel->run();
exit;
