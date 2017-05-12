#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use t::TestHTTP;

use IO::Async::Test;
use IO::Async::Loop;

use HTTP::Response;

use Net::Async::Webservice::S3;

my $loop = IO::Async::Loop->new;
testing_loop( $loop );

my $s3 = Net::Async::Webservice::S3->new(
   http => my $http = TestHTTP->new,
   access_key => 'K'x20,
   secret_key => 's'x40,
   max_retries => 1,
);

$loop->add( $s3 );

my $content = "Here is the entire content of the object";
my $etag    = '"HERE IS THE ETAG"';
my $stall_after = 10;

# stall with Future-returned value
{
   my $f = $s3->get_object(
      bucket => "bucket",
      key    => "one",
   );
   $f->on_fail( sub { die $_[0] } );

   my $req;
   wait_for { $req = $http->pending_request };

   is( $req->method,         "GET",                     'Request method' );
   is( $req->uri->authority, "bucket.s3.amazonaws.com", 'Request URI authority' );
   is( $req->uri->path,      "/one",                    'Request URI path' );

   $http->respond_header(
      HTTP::Response->new( 200, "OK", [
         ETag => $etag,
      ], "" )
   );
   $http->respond_more( substr( $content, 0, $stall_after ) );
   $http->fail( "Stall timeout", stall_timeout => );

   wait_for { $req = $http->pending_request };

   ok( $req, 'Received a second request after stall_timeout' );

   is( $req->method,         "GET",                     'Request method for resume' );
   is( $req->uri->authority, "bucket.s3.amazonaws.com", 'Request URI authority for resume' );
   is( $req->uri->path,      "/one",                    'Request URI path for resume' );

   is( $req->header( "If-Match" ), $etag,       'Request If-Match header for resume' );
   is( $req->header( "Range" ),    "bytes=10-", 'Request Range header for resume' );

   $http->respond(
      HTTP::Response->new( 206, "Partial Content", [
         "Content-Range" => sprintf( "bytes=%d-%d/%d", $stall_after, length( $content ) - $stall_after + 1, length( $content ) ),
         ETag            => $etag,
      ],
      substr( $content, $stall_after ) )
   );

   wait_for { $f->is_ready };

   is( scalar $f->get, $content, '$f->get returns content' );
}

# stall with on_chunk
{
   my $value = "";
   my $f = $s3->get_object(
      bucket => "bucket",
      key    => "one",
      on_chunk => sub {
         my ( undef, $more ) = @_;
         $value .= $more;
      },
   );
   $f->on_fail( sub { die $_[0] } );

   my $req;
   wait_for { $req = $http->pending_request };
   $http->respond_header(
      HTTP::Response->new( 200, "OK", [
         ETag => $etag,
      ], "" )
   );
   $http->respond_more( substr( $content, 0, $stall_after ) );
   $http->fail( "Stall timeout", stall_timeout => );

   wait_for { $req = $http->pending_request };

   ok( $req, 'Received a second request after stall_timeout' );
   is( $req->header( "Range" ),    "bytes=10-", 'Request Range header for resume' );

   $http->respond(
      HTTP::Response->new( 206, "Partial Content", [
         "Content-Range" => sprintf( "bytes=%d-%d/%d", $stall_after, length( $content ) - $stall_after + 1, length( $content ) ),
         ETag            => $etag,
      ],
      substr( $content, $stall_after ) )
   );

   wait_for { $f->is_ready };

   is( $value, $content, 'Accumulated value from on_chunk is content' );
}

# stall then etag mismatch
{
   my $f = $s3->get_object(
      bucket => "bucket",
      key    => "one",
   );

   my $req;
   wait_for { $req = $http->pending_request };
   $http->respond_header(
      HTTP::Response->new( 200, "OK", [
         ETag => $etag,
      ], "" )
   );
   $http->respond_more( substr( $content, 0, $stall_after ) );
   $http->fail( "Stall timeout", stall_timeout => );

   wait_for { $req = $http->pending_request };

   ok( $req, 'Received a second request after stall_timeout' );
   is( $req->header( "If-Match" ), $etag,       'Request If-Match header for resume' );

   $http->respond(
      HTTP::Response->new( 412, "Precondition Failed", [], "" )
   );

   wait_for { $f->is_ready };

   is( ( $f->failure )[1], "stall_timeout", '$f->failure is stall_timeout' );
}

done_testing;
