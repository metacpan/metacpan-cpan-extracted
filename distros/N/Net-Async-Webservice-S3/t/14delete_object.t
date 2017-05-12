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

# Delete
{
   my $f = $s3->delete_object(
      bucket => "bucket",
      key    => "three",
   );

   my $req;
   wait_for { $req = $http->pending_request or $f->is_ready };
   $f->get if $f->is_ready and $f->failure;

   is( $req->method,         "DELETE",                  'Request method' );
   is( $req->uri->authority, "bucket.s3.amazonaws.com", 'Request URI authority' );
   is( $req->uri->path,      "/three",                  'Request URI path' );

   $http->respond(
      HTTP::Response->new( 200, "OK", [], "" )
   );

   wait_for { $f->is_ready };

   ok( !$f->failure, '$f succeeds' );
}

# Test that timeout argument is set
{
   my $f;
   my $req;

   $s3->configure( timeout => 10 );
   $f = $s3->delete_object(
      bucket => "bucket",
      key    => "-four-",
   );

   wait_for { $req = $http->pending_request or $f->is_ready };
   $f->get if $f->is_ready and $f->failure;

   is( $req->header( "X-NaHTTP-Timeout" ), 10, 'Request has timeout set for configured' );
   $http->respond( 200, "OK", [] );

   $f = $s3->delete_object(
      bucket => "bucket",
      key    => "-four-",
      timeout => 20,
   );

   wait_for { $req = $http->pending_request or $f->is_ready };
   $f->get if $f->is_ready and $f->failure;

   is( $req->header( "X-NaHTTP-Timeout" ), 20, 'Request has timeout set for immediate' );
   $http->respond( 200, "OK", [] );
}

done_testing;
