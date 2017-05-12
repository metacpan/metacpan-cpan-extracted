#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use IO::Async::Test;
use IO::Async::Loop;

use Net::Async::HTTP;

my $CRLF = "\x0d\x0a"; # because \r\n isn't portable

my $loop = IO::Async::Loop->new();
testing_loop( $loop );

my $http = Net::Async::HTTP->new(
   user_agent => "", # Don't put one in request headers
);

$loop->add( $http );

my $port;
$loop->listen(
   host    => "127.0.0.1",
   service => 0,
   socktype => "stream",

   on_listen => sub {
      $port = shift->sockport;
   },

   on_stream => sub {
      my ( $stream ) = @_;

      $stream->configure(
         on_read => sub {
            my ( $self, $buffref ) = @_;
            return 0 unless $$buffref =~ m/$CRLF$CRLF/;

            $self->write( "HTTP/1.1 200 OK$CRLF" .
                          "Content-Type: text/plain$CRLF" .
                          "Connection: close$CRLF" .
                          "$CRLF" .
                          "OK" );

            $self->close_when_empty;

            return 0;
         },
      );

      $loop->add( $stream );
   },

   on_listen_error => sub { die "Test failed early - $_[-1]" },
   on_resolve_error => sub { die "Test failed early - $_[-1]" },
);

wait_for { defined $port };

my $local_uri = URI->new( "http://127.0.0.1:$port/" );

my $response;

my $connected_port;

$http->do_request(
   uri => $local_uri,

   on_ready => sub {
      my ( $conn ) = @_;
      $connected_port = $conn->read_handle->peerport;

      Future->done;
   },

   on_response => sub {
      $response = $_[0];
   },

   on_error => sub { die "Test failed early - $_[-1]" },
);

wait_for { defined $response };

is( $response->content_type, "text/plain", '$response->content_type' );
is( $response->content, "OK", '$response->content' );

is( $connected_port, $port, 'peerport visible within on_ready' );

done_testing;
