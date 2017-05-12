#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use IO::Async::Test;
use IO::Async::Loop;
use IO::Async::OS;
use IO::Async::Stream;

use Net::Async::WebSocket::Client;

use Protocol::WebSocket::Handshake::Server;

my $loop = IO::Async::Loop->new;
testing_loop( $loop );

my ( $serversock, $clientsock ) = IO::Async::OS->socketpair or
   die "Cannot socketpair - $!";

my @frames;

my $client = Net::Async::WebSocket::Client->new(
   on_frame => sub {
      my ( $self, $frame ) = @_;

      push @frames, $frame;
   },
);

ok( defined $client, '$client defined' );
isa_ok( $client, "Net::Async::WebSocket::Client", '$client' );

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
   $serversock->write( Protocol::WebSocket::Frame->new( "Here is my message" )->to_bytes );

   wait_for { @frames };

   is_deeply( \@frames, [ "Here is my message" ], 'received @frames' );

   undef @frames;
}

# send
{
   $client->send_frame( "Here is my response" );

   my $fb = Protocol::WebSocket::Frame->new;
   $stream = "";
   my $frame;
   wait_for_stream { $fb->append( $stream ); $stream = ""; $frame = $fb->next } $serversock => $stream;

   is( $frame, "Here is my response", 'responded $frame' );
}

# frames with false values
{
   $serversock->write( Protocol::WebSocket::Frame->new( "" )->to_bytes );

   wait_for { @frames };

   is_deeply( \@frames, [ "" ], 'received frame with false value' );
}

done_testing;
