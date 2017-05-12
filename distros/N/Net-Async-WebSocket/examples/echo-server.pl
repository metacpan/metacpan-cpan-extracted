#!/usr/bin/perl

use strict;

use IO::Async::Loop;
use Net::Async::WebSocket::Server;

my $PORT = 3000;

my $server = Net::Async::WebSocket::Server->new(
   on_client => sub {
      my ( undef, $client ) = @_;

      $client->configure(
         on_frame => sub {
            my ( $self, $frame ) = @_;
            $self->send_frame( $frame );
         },
      );
   }
);

my $loop = IO::Async::Loop->new;
$loop->add( $server );

$server->listen(
   family => "inet",
   service => $PORT,

   on_listen_error => sub { die "Cannot listen - $_[-1]" },
   on_resolve_error => sub { die "Cannot resolve - $_[-1]" },
);

$loop->loop_forever;
