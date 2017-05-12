#!/usr/bin/perl
# vim: filetype=perl

# Make sure that client sessions stay alive while they're waiting for
# sockets.  Also test the shutdown order, or more appropriately that
# Client::Keepalive can be shut down with outstanding sockets, without
# the whole program crashing and burning horribly.

use warnings;
use strict;
use lib qw(./mylib ../mylib);
use Test::More tests => 1;

sub POE::Kernel::ASSERT_DEFAULT () { 1 }

use POE;
use POE::Component::Client::Keepalive;
use POE::Component::Resolver;
use Socket qw(AF_INET);

use TestServer;
my $server_port = TestServer->spawn(0);

my $global_cm = POE::Component::Client::Keepalive->new(
  resolver => POE::Component::Resolver->new(af_order => [ AF_INET ]),
);

POE::Session->create(
  inline_states => {
    _start   => \&start,
    _stop    => \&stop,
    got_conn => \&got_conn,
  }
);

sub start {
  my $heap = $_[HEAP];

  $global_cm->allocate(
    scheme  => "http",
    addr    => "127.0.0.1",
    port    => $server_port,
    event   => "got_conn",
    context => "first",
  );
}

sub got_conn {
  my ($heap, $stuff) = @_[HEAP, ARG0];

  my $conn  = $stuff->{connection};
  my $which = $stuff->{context};

  ok( defined($conn), "got the connection" );

  $global_cm->shutdown() unless $heap->{cm_shutdown}++;
  TestServer->shutdown() unless $heap->{ts_shutdown}++;
}

sub stop {
  my $heap = $_[HEAP];

  $global_cm->shutdown() unless $heap->{cm_shutdown}++;
  TestServer->shutdown() unless $heap->{ts_shutdown}++;
}

POE::Kernel->run();
exit;
