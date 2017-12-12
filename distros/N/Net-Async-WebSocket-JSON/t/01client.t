#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use IO::Async::Test;
use IO::Async::Loop;
use IO::Async::OS;
use IO::Async::Stream;

use Net::Async::WebSocket::JSON::Client;

use Protocol::WebSocket::Handshake::Server;

my $loop = IO::Async::Loop->new;
testing_loop( $loop );

my ( $serversock, $clientsock ) = IO::Async::OS->socketpair or
   die "Cannot socketpair - $!";

my @received;

my $client = Net::Async::WebSocket::JSON::Client->new(
   on_json => sub {
      my ( $self, $data ) = @_;
      push @received, $data;
   },
);
$loop->add( $client );

my $f = $client->connect_handle( $clientsock,
   url => "ws://localhost/test",
);
$f->on_fail( sub { $f->get } );

my $h = Protocol::WebSocket::Handshake::Server->new;

my $stream = "";
wait_for_stream { $h->parse( $stream ); $stream = ""; $h->is_done } $serversock => $stream;

$serversock->write( $h->to_string );

wait_for { $f->is_ready };
$f->get;

# receive
{
   $serversock->write( Protocol::WebSocket::Frame->new( q({"data":"here"}) )->to_bytes );

   wait_for { @received };

   is_deeply( \@received, [ { data => "here" } ], 'received JSON data' );

   undef @received;
}

# send
{
   $client->send_json( { response => "here" } );

   my $fb = Protocol::WebSocket::Frame->new;
   $stream = "";
   my $frame;
   wait_for_stream { $fb->append( $stream ); $stream = ""; $frame = $fb->next } $serversock => $stream;

   is( $frame, q({"response":"here"}), 'sent JSON data' );
}

done_testing;
