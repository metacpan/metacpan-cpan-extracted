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

# U+2010 = HYPHEN = 0xe2 0x80 0x90
my $UTF_8_char  = "UTF\x{2010}8";
my $UTF_8_bytes = "UTF\xe2\x80\x908";

# receiving frame types
{
   my ( $got_text, $got_binary );
   $client->configure(
      on_text_frame   => sub { $got_text   = $_[1] },
      on_binary_frame => sub { $got_binary = $_[1] },
   );

   $serversock->write( Protocol::WebSocket::Frame->new(
      type   => "text",
      buffer => $UTF_8_char,  # Protocol::WebSocket::Frame will encode this
   )->to_bytes );

   wait_for { defined $got_text };
   is( $got_text, $UTF_8_char, 'received text frame' );

   # Valid UTF-8 encoding but should not be decoded
   $serversock->write( Protocol::WebSocket::Frame->new(
      type   => "binary",
      buffer => $UTF_8_bytes,
   )->to_bytes );

   wait_for { defined $got_binary };
   is( $got_binary, $UTF_8_bytes, 'received binary frame' );
}

# sending frame types
{
   my $fb = Protocol::WebSocket::Frame->new;
   my $bytes;

   $client->send_text_frame( $UTF_8_char );

   $stream = "";
   wait_for_stream { $fb->append( $stream ); $stream = ""; $bytes = $fb->next_bytes } $serversock => $stream;

   ok( $fb->is_text, 'sent text frame' );
   ok( $fb->masked, 'sent frame was masked' );
   is( $bytes, $UTF_8_bytes, 'content of text frame' );

   $client->send_binary_frame( $UTF_8_bytes );

   $stream = "";
   wait_for_stream { $fb->append( $stream ); $stream = ""; $bytes = $fb->next_bytes } $serversock => $stream;

   ok( $fb->is_binary, 'sent binary frame' );
   ok( $fb->masked, 'sent frame was masked' );
   is( $bytes, $UTF_8_bytes, 'content of binary frame' );
}

done_testing;
