#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use IO::Async::Test;
use IO::Async::Loop;
use IO::Async::OS;
use IO::Async::Stream;

use Tangence::Constants;
use Tangence::Registry;

use Net::Async::Tangence::Server;
use Net::Async::Tangence::Client;

use lib ".";
use t::Ball;

my $loop = IO::Async::Loop->new();
testing_loop( $loop );

my $registry = Tangence::Registry->new(
   tanfile => "t/Ball.tan",
);
my $ball = $registry->construct(
   "t::Ball",
   colour => "red",
   size   => 100,
);

my $server = Net::Async::Tangence::Server->new(
   registry => $registry,
);

$loop->add( $server );

my ( $conn1, $conn2 ) = map {
   my ( $S1, $S2 ) = IO::Async::OS->socketpair() or die "Cannot create socket pair - $!";
   my $conn;

   my $serverconn = $server->make_new_connection( $S1 );

   my $client = Net::Async::Tangence::Client->new( handle => $S2 );
   $loop->add( $client );

   my $ballproxy;
   wait_for { $ballproxy = $client->rootobj };

   $conn = {
      server    => $serverconn,
      client    => $client,
      ballproxy => $ballproxy,
   };

   my $f = $ballproxy->watch_property( "colour",
      on_set => sub { $conn->{colour} = shift },
   );

   wait_for { $f->is_ready };
   $f->get;

   $conn
} 1 .. 2;

$ball->set_prop_colour( "green" );

wait_for { defined $conn1->{colour} and defined $conn2->{colour} };

is( $conn1->{colour}, "green", '$colour is green from connection 1' );
is( $conn2->{colour}, "green", '$colour is green from connection 2' );

$conn1->{client}->close;

$loop->loop_once( 0 ) for 1 .. 10; # ensure the close event is properly flushed

$ball->set_prop_colour( "blue" );

undef $_->{colour} for $conn1, $conn2;
wait_for { defined $conn2->{colour} };

is( $conn1->{colour}, undef,  '$colour is still undef from (closed) connection 1' );
is( $conn2->{colour}, "blue", '$colour is blue from connection 2' );

done_testing;
