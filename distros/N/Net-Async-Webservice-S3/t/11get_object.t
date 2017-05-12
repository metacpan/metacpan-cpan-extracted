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
   max_retries => 1,
   http => my $http = TestHTTP->new,
   access_key => 'K'x20,
   secret_key => 's'x40,
);

$loop->add( $s3 );

# Simple get
{
   my $f = $s3->get_object(
      bucket => "bucket",
      key    => "one",
   );

   my $req;
   wait_for { $req = $http->pending_request or $f->is_ready };
   $f->get if $f->is_ready and $f->failure;

   is( $req->method,         "GET",                     'Request method' );
   is( $req->uri->authority, "bucket.s3.amazonaws.com", 'Request URI authority' );
   is( $req->uri->path,      "/one",                    'Request URI path' );

   $http->respond(
      HTTP::Response->new( 200, "OK", [
         Content_Type => "text/plain",
      ], <<'EOF' )
Here is the key
EOF
   );

   wait_for { $f->is_ready };

   my ( $value, $response ) = $f->get;
   is( $value, "Here is the key\n", '$value for simple get' );
   is( $response->content_type, "text/plain", '$response->content_type for simple get' );
}

# Streaming get
{
   my ( $header, $bytes );
   my $f = $s3->get_object(
      bucket => "bucket",
      key    => "one",
      on_chunk => sub {
         ( $header, $bytes ) = @_;
      },
   );

   wait_for { $http->pending_request or $f->is_ready };
   $f->get if $f->is_ready and $f->failure;

   $http->respond_header(
      HTTP::Response->new( 200, "OK", [
         Content_Type => "text/plain",
      ], "" )
   );

   $http->respond_more( "some bytes" );

   wait_for { defined $header };
   is( $header->content_type, "text/plain", '$header->content_type for chunked get' );
   is( $bytes, "some bytes", '$bytes for chunked get' );

   $http->respond_done;

   wait_for { $f->is_ready };
}

# Get byte range
{
   my $f = $s3->get_object(
      bucket => "bucket",
      key    => "one",
      byte_range => "8-",
   );

   my $req;
   wait_for { $req = $http->pending_request or $f->is_ready };
   $f->get if $f->is_ready and $f->failure;

   is( $req->method,         "GET",                     'Request method' );
   is( $req->uri->authority, "bucket.s3.amazonaws.com", 'Request URI authority' );
   is( $req->uri->path,      "/one",                    'Request URI path' );
   is( $req->header( "Range" ), "bytes=8-",             'Request Range header' );

   $http->respond(
      HTTP::Response->new( 206, "Partial Content", [
         Content_Type => "text/plain",
         Content_Range => "bytes 8-15/16",
      ], <<'EOF' )
the key
EOF
   );

   wait_for { $f->is_ready };

   my ( $value, $response ) = $f->get;
   is( $value, "the key\n", '$value for ranged get' );
   is( $response->content_type, "text/plain", '$response->content_type for ranged get' );
}

# Get with If-Match
{
   my $f = $s3->get_object(
      bucket => "bucket",
      key    => "one",
      if_match => '"my-etag-here"',
   );

   my $req;
   wait_for { $req = $http->pending_request or $f->is_ready };
   $f->get if $f->is_ready and $f->failure;

   is( $req->method,         "GET",                     'Request method' );
   is( $req->uri->authority, "bucket.s3.amazonaws.com", 'Request URI authority' );
   is( $req->uri->path,      "/one",                    'Request URI path' );
   is( $req->header( "If-Match" ), '"my-etag-here"',    'Request If-Match header' );

   $http->respond(
      HTTP::Response->new( 412, "Precondition Failed", [], "" ),
   );

   wait_for { $f->is_ready };

   ok( scalar $f->failure, '$f fails after 412 error' );
   my ( $failure, $name, $resp ) = $f->failure;
   is( $resp->code, 412, 'failure request has ->code 412' );
}

# Get with implied bucket and prefix
{
   $s3->configure(
      bucket => "bucket",
      prefix => "subdir/",
   );

   my $f = $s3->get_object(
      key => "1",
   );

   my $req;
   wait_for { $req = $http->pending_request or $f->is_ready };
   $f->get if $f->is_ready and $f->failure;

   is( $req->method,         "GET",                     'Request method' );
   is( $req->uri->authority, "bucket.s3.amazonaws.com", 'Request URI authority' );
   is( $req->uri->path,      "/subdir/1",               'Request URI path' );

   $http->respond(
      HTTP::Response->new( 200, "OK", [
         Content_Type => "text/plain",
      ], <<'EOF' )
More content
EOF
   );

   wait_for { $f->is_ready };
   $f->get;

   $s3->configure(
      bucket => undef,
      prefix => undef,
   );
}

# Get with metadata
{
   my $f = $s3->get_object(
      bucket => "bucket",
      key    => "ONE",
   );

   my $req;
   wait_for { $req = $http->pending_request or $f->is_ready };
   $f->get if $f->is_ready and $f->failure;

   $http->respond(
      HTTP::Response->new( 200, "OK", [
         Content_Type => "text/plain",
         'X-Amz-Meta-One' => "one",
      ], <<'EOF' )
value
EOF
   );

   wait_for { $f->is_ready };

   my ( $value, $response, $meta ) = $f->get;
   is_deeply( $meta, { One => "one" }, '$meta for get with metadata' );
}

# get error
{
   my $f = $s3->get_object(
      bucket => "bucket",
      key    => "five",
   );

   my $req;
   wait_for { $req = $http->pending_request or $f->is_ready };
   $f->get if $f->is_ready and $f->failure;

   $http->respond(
      HTTP::Response->new( 404, "Not Found", [], '' )
   );

   wait_for { $f->is_ready };

   ok( scalar $f->failure, '$f fails after 404 error' );
   my ( $failure, $name, $resp ) = $f->failure;
   is( $resp->code, 404, 'failure request has ->code 404' );
}

# Simple head
{
   my $f = $s3->head_object(
      bucket => "bucket",
      key    => "one",
   );

   my $req;
   wait_for { $req = $http->pending_request or $f->is_ready };
   $f->get if $f->is_ready and $f->failure;

   is( $req->method,         "HEAD",                    'Request method' );
   is( $req->uri->authority, "bucket.s3.amazonaws.com", 'Request URI authority' );
   is( $req->uri->path,      "/one",                    'Request URI path' );

   $http->respond(
      HTTP::Response->new( 200, "OK", [
         Content_Type => "text/plain",
      ], '' )
   );

   wait_for { $f->is_ready };

   my ( $response ) = $f->get;
   is( $response->content_type, "text/plain", '$response->content_type for simple get' );
}

# head error
{
   my $f = $s3->head_object(
      bucket => "bucket",
      key    => "five",
   );

   my $req;
   wait_for { $req = $http->pending_request or $f->is_ready };
   $f->get if $f->is_ready and $f->failure;

   $http->respond(
      HTTP::Response->new( 404, "Not Found", [], '' )
   );

   wait_for { $f->is_ready };

   ok( scalar $f->failure, '$f fails after 404 error' );
   my ( $failure, $name, $resp ) = $f->failure;
   is( $resp->code, 404, 'failure request has ->code 404' );
}

# head_then_get
{
   my $head_f = $s3->head_then_get_object(
      bucket => "bucket",
      key    => "one",
   );

   my $req;
   wait_for { $req = $http->pending_request or $head_f->is_ready };
   $head_f->get if $head_f->is_ready and $head_f->failure;

   is( $req->method,         "GET",                     'Request method' );
   is( $req->uri->authority, "bucket.s3.amazonaws.com", 'Request URI authority' );
   is( $req->uri->path,      "/one",                    'Request URI path' );

   $http->respond_header(
      HTTP::Response->new( 200, "OK", [
         Content_Type => "text/plain",
         'X-Amz-Meta-One' => "one",
      ], "" )
   );
   $http->respond_more( "And now here is some content\n" );

   wait_for { $head_f->is_ready };

   my ( $value_f, $header, $meta ) = $head_f->get;

   ok( !$value_f->is_ready, '$value_f is not yet ready before sending body content' );
   is( $header->content_type, "text/plain", '$header->content_type for head_then_get' );
   is_deeply( $meta, { One => "one" }, '$meta for head_then_get' );

   $http->respond_done;

   wait_for { $value_f->is_ready };

   my ( $value, $header_2, $meta_2 ) = $value_f->get;
   is( $value, "And now here is some content\n", '$value after completion' );
   is( $header_2, $header, '$header again from value future' );
   is_deeply( $meta_2, $meta, '$meta again from value future' );
}

# head_then_get error
{
   my $head_f = $s3->head_then_get_object(
      bucket => "bucket",
      key    => "five",
   );

   my $req;
   wait_for { $req = $http->pending_request or $head_f->is_ready };
   $head_f->get if $head_f->is_ready and $head_f->failure;

   $http->respond(
      HTTP::Response->new( 404, "Not Found", [], "Object was not found" )
   );

   wait_for { $head_f->is_ready };

   ok( scalar $head_f->failure, '$head_f fails after 404 error' );
   my ( $failure, $name, $resp ) = $head_f->failure;
   is( $resp->code, 404, 'failure request has ->code 404' );
}

# head_then_get cancellation
{
   my $head_f = $s3->head_then_get_object(
      bucket => "bucket",
      key    => "one",
   );

   my $req;
   wait_for { $req = $http->pending_request or $head_f->is_ready };
   $head_f->get if $head_f->is_ready and $head_f->failure;

   $head_f->cancel;

   $http->respond_header(
      HTTP::Response->new( 200, "OK", [
         Content_Type => "text/plain",
         'X-Amz-Meta-One' => "one",
      ], "" )
   );
   $http->respond_more( "And now here is some content\n" );
   $http->respond_done;

   $head_f = $s3->head_then_get_object(
      bucket => "bucket",
      key    => "one",
   );

   undef $req;
   wait_for { $req = $http->pending_request or $head_f->is_ready };
   $head_f->get if $head_f->is_ready and $head_f->failure;

   $head_f->cancel;

   $http->respond(
      HTTP::Response->new( 404, "Not Found", [], "" )
   );
}

# Test that timeout argument is set only for direct argument
{
   my $f;
   my $req;

   $s3->configure( timeout => 10 );
   $f = $s3->get_object(
      bucket => "bucket",
      key    => "-one-",
   );

   wait_for { $req = $http->pending_request or $f->is_ready };
   $f->get if $f->is_ready and $f->failure;

   is( $req->header( "X-NaHTTP-Timeout" ), undef, 'Request has no timeout for configured' );
   $http->respond( HTTP::Response->new( 200, "OK", [] ) );

   $f = $s3->get_object(
      bucket  => "bucket",
      key     => "-one-",
      timeout => 20,
   );

   wait_for { $req = $http->pending_request or $f->is_ready };
   $f->get if $f->is_ready and $f->failure;

   is( $req->header( "X-NaHTTP-Timeout" ), 20, 'Request has timeout set for immediate' );
   $http->respond( HTTP::Response->new( 200, "OK", [] ) );
}

done_testing;
