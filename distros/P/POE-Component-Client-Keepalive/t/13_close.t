#!/usr/bin/perl

# Test close() on connections. 

use warnings;
use strict;
use lib qw(./mylib ../mylib);
use Test::More tests => 4;

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
    got_first_conn    => \&got_first_conn,
    got_second_conn   => \&got_second_conn,
    nothing           => sub { },
  }
);

sub start {
  my $heap = $_[HEAP];

  $heap->{others} = 0;

  $heap->{cm} = POE::Component::Client::Keepalive->new(
    keep_alive   => 1,
    max_open     => 1,
    max_per_host => 1,
    resolver     => POE::Component::Resolver->new(af_order => [ AF_INET ]),
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
  my $which = $stuff->{context};
  ok(!defined($stuff->{from_cache}), "$which uses a new connection");
  ok(defined($conn), "first request honored asynchronously");


  $conn->start( InputEvent => 'nothing' );

  $conn->close();

  undef $conn;

  $heap->{cm}->allocate(
    scheme => "http",
    addr => "localhost",
    port => $server_port,
    event => "got_second_conn",
    context => "second"
  );
}


sub got_second_conn {
  my ($kernel, $heap, $stuff) = @_[KERNEL, HEAP, ARG0];

  my $conn  = $stuff->{connection};
  my $which = $stuff->{context};
  ok(defined($conn), "$which request honored asynchronously");
  ok(!defined ($stuff->{from_cache}), "$which uses a new connection");

  TestServer->shutdown();
  $_[HEAP]->{cm}->shutdown();

}

POE::Kernel->run();
exit;
