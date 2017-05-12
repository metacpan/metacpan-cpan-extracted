#!/usr/bin/perl

use strict;
use warnings;

use Net::Async::HTTP::Server;
use IO::Async::Loop;

use HTTP::Response;

use Getopt::Long;

GetOptions(
   'ssl|S' => \my $SSL,
) or exit 1;

require IO::Async::SSL if $SSL;

my $loop = IO::Async::Loop->new();

my $httpserver = Net::Async::HTTP::Server->new(
   on_request => sub {
      my $self = shift;
      my ( $req ) = @_;

      my $response = HTTP::Response->new( 200 );
      $response->add_content( "Hello, world!\n" );
      $response->content_type( "text/plain" );

      $response->content_length( length $response->content );

      $req->respond( $response );
   },
);

$loop->add( $httpserver );

$httpserver->listen(
   addr => {
      family   => "inet6",
      socktype => "stream",
      port     => $SSL ? 8443 : 8080,
   },
   on_listen_error => sub { die "Cannot listen - $_[-1]\n" },
   ( $SSL ? (
      extensions    => [ 'SSL' ],
      SSL_key_file  => "t/privkey.pem",
      SSL_cert_file => "t/server.pem", )
      : () ),
);

$loop->run;
