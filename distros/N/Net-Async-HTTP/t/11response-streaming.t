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

my $peersock;

no warnings 'redefine';
local *IO::Async::Handle::connect = sub {
   my $self = shift;
   my %args = @_;

   ( my $selfsock, $peersock ) = IO::Async::OS->socketpair() or die "Cannot create socket pair - $!";
   $self->set_handle( $selfsock );

   return Future->new->done( $self );
};

my $header;
my $body;
my $body_is_done;

$http->do_request(
   uri => URI->new( "http://my.server/here" ),

   on_header => sub {
      ( $header ) = @_;
      $body = "";
      return sub {
         @_ ? $body .= $_[0] : $body_is_done++;
      }
   },
   on_error => sub { die "Test died early - $_[0]" },
);

# Wait for request but don't really care what it actually is
my $request_stream = "";
wait_for_stream { $request_stream =~ m/$CRLF$CRLF/ } $peersock => $request_stream;

$peersock->syswrite( "HTTP/1.1 200 OK$CRLF" .
                     "Content-Length: 15$CRLF" .
                     "Content-Type: text/plain$CRLF" .
                     "Connection: Keep-Alive$CRLF" .
                     "$CRLF" );

wait_for { defined $header };

isa_ok( $header, "HTTP::Response", '$header for Content-Length' );
is( $header->content_length, 15, '$header->content_length' );
is( $header->content_type, "text/plain", '$header->content_type' );

$peersock->syswrite( "Hello, " );

wait_for { length $body == 7 };

is( $body, "Hello, ", '$body partial Content-Length' );

$peersock->syswrite( "world!$CRLF" );

wait_for { $body_is_done };
is( $body, "Hello, world!$CRLF", '$body' );

undef $header;
undef $body;
undef $body_is_done;

$http->do_request(
   uri => URI->new( "http://my.server/here" ),

   on_header => sub {
      ( $header ) = @_;
      $body = "";
      return sub {
         @_ ? $body .= $_[0] : $body_is_done++;
      }
   },
   on_error => sub { die "Test died early - $_[0]" },
);

# Wait for request but don't really care what it actually is
$request_stream = "";
wait_for_stream { $request_stream =~ m/$CRLF$CRLF/ } $peersock => $request_stream;

$peersock->syswrite( "HTTP/1.1 200 OK$CRLF" .
                     "Content-Length: 15$CRLF" .
                     "Content-Type: text/plain$CRLF" .
                     "Connection: Keep-Alive$CRLF" .
                     "Transfer-Encoding: chunked$CRLF" .
                     "$CRLF" );

wait_for { defined $header };

isa_ok( $header, "HTTP::Response", '$header for chunked' );
is( $header->content_length, 15, '$header->content_length' );
is( $header->content_type, "text/plain", '$header->content_type' );

$peersock->syswrite( "7$CRLF" . "Hello, " . $CRLF );

wait_for { length $body == 7 };
is( $body, "Hello, ", '$body partial chunked' );

$peersock->syswrite( "8$CRLF" . "world!$CRLF" . $CRLF );

wait_for { length $body == 15 };
is( $body, "Hello, world!$CRLF", '$body partial(2) chunked' );

$peersock->syswrite( "0$CRLF" . $CRLF );

wait_for { $body_is_done };
is( $body, "Hello, world!$CRLF", '$body chunked' );

undef $header;
undef $body;
undef $body_is_done;

$http->do_request(
   uri => URI->new( "http://my.server/here" ),

   on_header => sub {
      ( $header ) = @_;
      $body = "";
      return sub {
         @_ ? $body .= $_[0] : $body_is_done++;
      }
   },
   on_error => sub { die "Test died early - $_[0]" },
);

# Wait for request but don't really care what it actually is
$request_stream = "";
wait_for_stream { $request_stream =~ m/$CRLF$CRLF/ } $peersock => $request_stream;

$peersock->syswrite( "HTTP/1.0 200 OK$CRLF" .
                     "Content-Type: text/plain$CRLF" .
                     "Connection: close$CRLF" .
                     "$CRLF" );

wait_for { defined $header };

isa_ok( $header, "HTTP::Response", '$header for EOF' );
is( $header->content_type, "text/plain", '$header->content_type' );

$peersock->syswrite( "Hello, " );

wait_for { length $body == 7 };

is( $body, "Hello, ", '$body partial EOF' );

$peersock->syswrite( "world!$CRLF" );

wait_for { length $body == 15 };

is( $body, "Hello, world!$CRLF", '$body' );

$peersock->close;

wait_for { $body_is_done };

done_testing;
