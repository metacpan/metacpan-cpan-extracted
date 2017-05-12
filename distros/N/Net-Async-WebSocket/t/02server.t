#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use IO::Async::Test;
use IO::Async::Loop;

use Net::Async::WebSocket::Server;

use Protocol::WebSocket::Frame;
use Protocol::WebSocket::Handshake::Client;

use IO::Socket::INET;

my $loop = IO::Async::Loop->new;
testing_loop( $loop );

my $serversock = IO::Socket::INET->new(
   LocalHost => "127.0.0.1",
   Listen => 1,
) or die "Cannot allocate listening socket - $@";

my $client;
my @frames;

my $server = Net::Async::WebSocket::Server->new(
   handle => $serversock,

   on_handshake => sub {
     my ( $self, $stream, $hs, $continue ) = @_;
     $continue->( $hs->req->origin eq "http://localhost" );
   },

   on_client => sub {
      my ( undef, $thisclient ) = @_;

      $client = $thisclient;

      $thisclient->configure(
         on_frame => sub {
            my ( $self, $frame ) = @_;

            push @frames, $frame;
         },
      );
   },
);

ok( defined $server, '$server defined' );
isa_ok( $server, "Net::Async::WebSocket::Server", '$server' );

$loop->add( $server );

my $clientsock = IO::Socket::INET->new(
   PeerHost => $serversock->sockhost,
   PeerPort => $serversock->sockport,
) or die "Cannot connect to testing server - $@";

my $h = Protocol::WebSocket::Handshake::Client->new(
   url => "ws://localhost/test",
);

$clientsock->write( $h->to_string );

my $stream = "";
wait_for_stream { $h->parse( $stream ); $stream = ""; $h->is_done } $clientsock => $stream;

ok( defined $client, '$client is defined' );

$clientsock->write( Protocol::WebSocket::Frame->new( "Here is my message" )->to_bytes );

wait_for { @frames };

is_deeply( \@frames, [ "Here is my message" ], 'received @frames' );

undef @frames;

$client->send_frame( "Here is my response" );

my $fb = Protocol::WebSocket::Frame->new;
$stream = "";
my $frame;
wait_for_stream { $fb->append( $stream ); $stream = ""; $frame = $fb->next } $clientsock => $stream;

is( $frame, "Here is my response", 'responded $frame' );

done_testing;
