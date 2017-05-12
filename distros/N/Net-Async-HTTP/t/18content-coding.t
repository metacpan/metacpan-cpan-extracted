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
   decode_content => 1,
);
$loop->add( $http );

my $TEST_CONTENT = "Here is the compressed content\n";

my $peersock;
no warnings 'redefine';
local *IO::Async::Handle::connect = sub {
   my $self = shift;
   my %args = @_;

   $args{host}    eq "host" or die "Expected $args{host} eq 'host'";
   $args{service} eq "80"   or die "Expected $args{service} eq 80";

   ( my $selfsock, $peersock ) = IO::Async::OS->socketpair() or die "Cannot create socket pair - $!";
   $self->set_handle( $selfsock );

   return Future->new->done( $self );
};

# RFC 2616 "gzip"
SKIP: {
   skip "Compress::Raw::Zlib not available", 4 unless eval { require Compress::Raw::Zlib and $Compress::Raw::Zlib::VERSION >= 2.057 };
   diag( "Using optional dependency Compress::Raw::Zlib $Compress::Raw::Zlib::VERSION" );

   my $f = $http->GET( "http://host/gzip" );
   $f->on_fail( sub { $f->get } );

   {
      my $request_stream = "";
      wait_for_stream { $request_stream =~ m/$CRLF$CRLF/ } $peersock => $request_stream;

      my ( undef, @headers ) = split m/$CRLF/, $request_stream;
      ok( scalar( grep { m/^Accept-Encoding: / } @headers ), 'Request as an Accept-Encoding header' );

      my $compressor = Compress::Raw::Zlib::Deflate->new(
         -WindowBits => Compress::Raw::Zlib::WANT_GZIP(),
         -AppendOutput => 1,
      );
      my $content = "";
      $compressor->deflate( $TEST_CONTENT, $content );
      $compressor->flush( $content );

      $peersock->syswrite( sprintf "HTTP/1.1 200 OK$CRLF" .
         "Content-Length: %d$CRLF" .
         "Content-Type: text/plain$CRLF" .
         "Content-Encoding: gzip$CRLF" .
         $CRLF . "%s",
         length $content, $content );
   }

   my $response = $f->get;

   is( $response->content, $TEST_CONTENT, '$response->content is decompressed from gzip' );
   ok( !defined $response->header( "Content-Encoding" ), '$response has no Content-Encoding' );
   is( $response->header( "X-Original-Content-Encoding" ), "gzip", '$response has X-Original-Content-Encoding' );
}

# RFC 2616 "deflate"
SKIP: {
   skip "Compress::Raw::Zlib not available", 3 unless eval { require Compress::Raw::Zlib and $Compress::Raw::Zlib::VERSION >= 2.057 };

   my $f = $http->GET( "http://host/deflate" );
   $f->on_fail( sub { $f->get } );

   {
      my $request_stream = "";
      wait_for_stream { $request_stream =~ m/$CRLF$CRLF/ } $peersock => $request_stream;

      my $compressor = Compress::Raw::Zlib::Deflate->new(
         -WindowBits => 15,
         -AppendOutput => 1,
      );
      my $content = "";
      $compressor->deflate( $TEST_CONTENT, $content );
      $compressor->flush( $content );

      $peersock->syswrite( sprintf "HTTP/1.1 200 OK$CRLF" .
         "Content-Length: %d$CRLF" .
         "Content-Type: text/plain$CRLF" .
         "Content-Encoding: deflate$CRLF" .
         $CRLF . "%s",
         length $content, $content );
   }

   my $response = $f->get;

   is( $response->content, $TEST_CONTENT, '$response->content is decompressed from deflate' );
   ok( !defined $response->header( "Content-Encoding" ), '$response has no Content-Encoding' );
   is( $response->header( "X-Original-Content-Encoding" ), "deflate", '$response has X-Original-Content-Encoding' );
}

SKIP: {
   # Compress::Bzip2 2.09 appears to fail
   skip "Compress::Bzip2 not available", 3 unless eval { require Compress::Bzip2 and $Compress::Bzip2::VERSION >= 2.10 };
   diag( "Using optional dependency Compress::Bzip2 $Compress::Bzip2::VERSION" );

   my $f = $http->GET( "http://host/bzip2" );
   $f->on_fail( sub { $f->get } );

   {
      my $request_stream = "";
      wait_for_stream { $request_stream =~ m/$CRLF$CRLF/ } $peersock => $request_stream;

      my $compressor = Compress::Bzip2::bzdeflateInit();
      my $content = "";
      $content .= $compressor->bzdeflate( my $tmp = $TEST_CONTENT );
      $content .= $compressor->bzclose;

      $peersock->syswrite( sprintf "HTTP/1.1 200 OK$CRLF" .
         "Content-Length: %d$CRLF" .
         "Content-Type: text/plain$CRLF" .
         "Content-Encoding: bzip2$CRLF" .
         $CRLF . "%s",
         length $content, $content );
   }

   my $response = $f->get;

   is( $response->content, $TEST_CONTENT, '$response->content is decompressed from bzip2' );
   ok( !defined $response->header( "Content-Encoding" ), '$response has no Content-Encoding' );
   is( $response->header( "X-Original-Content-Encoding" ), "bzip2", '$response has X-Original-Content-Encoding' );
}

done_testing;
