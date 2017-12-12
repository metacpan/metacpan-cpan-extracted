#!/usr/bin/perl

use strict;

use IO::Async::Loop;
use Net::Async::WebSocket::Server;

my $PORT = 3000;

my $server = Net::Async::WebSocket::Server->new(
   on_client => sub {
      my ( undef, $client ) = @_;

      $client->configure(
         on_text_frame => sub {
            my ( $self, $frame ) = @_;
            $self->send_text_frame( $frame );
         },
      );
   }
);

my $loop = IO::Async::Loop->new;
$loop->add( $server );

$server->listen(
   family => "inet",
   service => $PORT,
)->get;

$loop->run;
