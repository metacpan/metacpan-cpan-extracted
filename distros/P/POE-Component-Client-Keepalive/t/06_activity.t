#!/usr/bin/perl

# Test activity on idle connections in the pool.

use warnings;
use strict;
use lib qw(./mylib ../mylib);
use Test::More tests => 5;

sub POE::Kernel::ASSERT_DEFAULT () { 1 }

use POE;
use POE::Component::Client::Keepalive;
use POE::Component::Resolver;
use Socket qw(AF_INET);

use TestServer;
my $server_port = TestServer->spawn(0);

POE::Session->create(
  inline_states => {
    _child             => sub { },
    _start             => \&start,
    _stop              => sub { },
    check_for_input    => \&check_for_input,
    got_conn           => \&got_conn,
    got_conn2           => \&got_conn2,
    got_error          => \&got_error,
    got_input          => \&got_input,
    got_timeout        => \&got_timeout,
    shutdown_server    => \&shutdown_server,
  }
);

# Start the connection manager, and allocate a connection to our test
# server.

sub start {
  my $heap = $_[HEAP];
  $heap->{cm} = POE::Component::Client::Keepalive->new(
    resolver => POE::Component::Resolver->new(af_order => [ AF_INET ]),
  );
  $heap->{cm}->allocate(
    scheme  => "http",
    addr    => "localhost",
    port    => $server_port,
    event   => "got_conn",
    context => "first",
  );
}

# A connection has been allocated.
# Tell the test server to send us something.
# Discard the connection before we can retrieve from it.

sub got_conn {
  my ($heap, $stuff) = @_[HEAP, ARG0..$#_];

  my $conn = $stuff->{connection};
  my $which = $stuff->{context};
  ok(defined($conn), "$which connection established asynchronously");
  ok(not (defined ($stuff->{from_cache})), "$which connection request deferred");

  TestServer->send_something();

  $_[KERNEL]->delay(check_for_input => 1);

  # The connection goes free when it drops out of scope here.
  # Everything that was sent to it remains unread.
}

# Reallocate the free socket.  It should be asynchronous because there
# was data on the socket and the connection could not be reused.

sub check_for_input {
  my ($kernel, $heap) = @_[KERNEL, HEAP];

  $heap->{cm}->allocate(
    scheme  => "http",
    addr    => "localhost",
    port    => $server_port,
    event   => "got_conn2",
    context => "first",
  );

  $kernel->delay(shutdown_server => 1);
}

sub got_conn2 {
  my ($kernel, $heap, $stuff) = @_[KERNEL, HEAP, ARG0..$#_];

  $heap->{conn} = $stuff->{connection};
  is(
    $stuff->{from_cache}, undef,
    "second connection established assynchronously"
  );

  $heap->{conn}->start(
    InputEvent => "got_input",
  );

  ok(defined($heap->{conn}->wheel()), "connection contains a wheel");
}

sub got_input {
  $_[HEAP]->{got_input} = 1;
}

sub shutdown_server {
  my ($kernel, $heap) = @_[KERNEL, HEAP];

  ok(!$heap->{got_input}, "didn't receive any input");

  delete $heap->{conn};
  TestServer->shutdown();
  $heap->{cm}->shutdown();
}

POE::Kernel->run();
exit;
