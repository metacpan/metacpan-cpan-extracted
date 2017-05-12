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
            return 0 unless $$buffref =~ s/^(.*?)$CRLF$CRLF//s;

            $self->write( "HTTP/1.1 200 OK$CRLF" .
                          "Content-Type: text/plain$CRLF" .
                          "Content-Length: 2$CRLF" .
                          "Connection: Keep-Alive$CRLF" .
                          "$CRLF" .
                          "OK" );

            return 1;
         },
      );

      $loop->add( $stream );
   },

   on_listen_error => sub { die "Test failed early - $_[-1]" },
   on_resolve_error => sub { die "Test failed early - $_[-1]" },
);

wait_for { defined $port };

my @local_uris = map { URI->new( "http://127.0.0.1:$port/page/$_" ) } 1 .. 2;

my @responses;

$http->do_request(
   uri => $_,

   on_response => sub {
      push @responses, $_[0];
   },

   on_error => sub { die "Test failed early - $_[-1]" },
) for @local_uris;

wait_for { @responses == 2 };

is( $responses[0]->content_type, "text/plain", '$response->content_type' );
is( $responses[0]->content, "OK", '$response->content' );

is( $responses[1]->content_type, "text/plain", '$response->content_type' );
is( $responses[1]->content, "OK", '$response->content' );

done_testing;
