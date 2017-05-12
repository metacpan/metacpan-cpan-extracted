#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use IO::Async::Test;
use IO::Async::Loop;

use Net::Async::WebSocket::Client;
use Net::Async::WebSocket::Server;

use IO::Socket::INET;

my $loop = IO::Async::Loop->new;
testing_loop( $loop );

my $serversock = IO::Socket::INET->new(
   LocalHost => "127.0.0.1",
   Listen => 1,
) or die "Cannot allocate listening socket - $@";

my @serverframes;

my $acceptedclient;
my $server = Net::Async::WebSocket::Server->new(
   handle => $serversock,

   on_client => sub {
      my ( undef, $thisclient ) = @_;

      $acceptedclient = $thisclient;

      $thisclient->configure(
         on_frame => sub {
            my ( $self, $frame ) = @_;

            push @serverframes, $frame;
         },
      );
   },
);

$loop->add( $server );

my @clientframes;

my $client = Net::Async::WebSocket::Client->new(
   on_frame => sub {
      my ( $self, $frame ) = @_;

      push @clientframes, $frame;
   },
);

$loop->add( $client );

$client->connect(
   host    => $serversock->sockhost,
   service => $serversock->sockport,
   url => "ws://localhost/test",
)->get;

$client->send_frame( "Here is my message" );

wait_for { @serverframes };

is_deeply( \@serverframes, [ "Here is my message" ], 'received @serverframes' );

$acceptedclient->send_frame( "Here is my response" );

wait_for { @clientframes };

is_deeply( \@clientframes, [ "Here is my response" ], 'received @clientframes' );

done_testing;
