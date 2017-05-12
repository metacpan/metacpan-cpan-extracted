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
);

$loop->add( $s3 );

# Fails first time
{
   my $f = $s3->list_bucket(
      bucket => "bucket",
      prefix => "",
      delimiter => "/",
   );

   wait_for { $http->pending_request };
   $http->respond(
      HTTP::Response->new( 500, "Service Unavailable", [], "" )
   );

   ok( !$f->is_ready, '$f not ready yet after first failure' );

   wait_for { $http->pending_request };
   $http->respond(
      HTTP::Response->new( 200, "OK", [
         Content_Type => "application/xml",
      ], <<'EOF' )
<?xml version="1.0" encoding="UTF-8"?>
<ListBucketResult xmlns="http://s3.amazonaws.com/doc/2006-03-01/">
  <Name>bucket</Name>
  <Prefix></Prefix>
  <Marker></Marker>
  <MaxKeys>100</MaxKeys>
  <Delimiter>/</Delimiter>
  <IsTruncated>false</IsTruncated>
</ListBucketResult>
EOF
   );

   wait_for { $f->is_ready };
   is( scalar $f->failure, undef, '$f succeeds after one retry' );
}

# Fails every time
{
   my $f = $s3->list_bucket(
      bucket => "bucket",
      prefix => "",
      delimiter => "/",
   );

   my $count = 0;
   while( !$f->is_ready ) {
      $count++;
      wait_for { $http->pending_request };
      $http->respond(
         HTTP::Response->new( 500, "Service Unavailable", [], "" )
      );
   }

   is( scalar $f->failure, "500 Service Unavailable", '$f fails eventually' );
   is( $count, 3, 'Attempted 3 times total' );
}

# HTTP 4xx errors should not be retried
{
   my $f = $s3->list_bucket(
      bucket => "bucket",
      prefix => "NOTHERE",
      delimiter => "/",
   );

   wait_for { $http->pending_request };
   $http->respond(
      HTTP::Response->new( 404, "Not Found", [], "" )
   );

   ok( $f->is_ready, '$f is ready after single HTTP 404 failure' );
   is( scalar $f->failure, "404 Not Found", '$f->failure for HTTP 404 failure' );
}

done_testing;
