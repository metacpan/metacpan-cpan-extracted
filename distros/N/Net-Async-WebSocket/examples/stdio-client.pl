#!/usr/bin/perl

use strict;

use IO::Async::Loop;
use IO::Async::Stream;
use Net::Async::WebSocket::Client;

my $HOST = shift @ARGV or die "Need HOST";
my $PORT = shift @ARGV or die "Need PORT";

my ( $client, $stdio );

$client = Net::Async::WebSocket::Client->new(
   on_text_frame => sub {
      my ( $self, $frame ) = @_;
      $stdio->write( $frame );
   },
);

$stdio = IO::Async::Stream->new_for_stdio(
   on_read => sub {
      my ( $self, $buffref ) = @_;
      $client->send_text_frame( $$buffref );
      $$buffref = "";
   },
);

my $loop = IO::Async::Loop->new;
$loop->add( $client );
$loop->add( $stdio );

$client->connect(
   host => $HOST,
   service => $PORT,
   url => "ws://$HOST:$PORT/",
)->get;

print "Connected; go ahead...\n";

$loop->run;
