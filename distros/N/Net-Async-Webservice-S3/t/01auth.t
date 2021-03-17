#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Test::Async::HTTP;

use IO::Async::Test;
use IO::Async::Loop;
use Digest::MD5 qw( md5_hex );

use HTTP::Response;

my $time;
BEGIN {
   # Auth hash includes signature of the date. So we need them repeatable for
   # this test
   *CORE::GLOBAL::time = sub { return $time };
}

use Net::Async::Webservice::S3;

my $loop = IO::Async::Loop->new;
testing_loop( $loop );

my $s3 = Net::Async::Webservice::S3->new(
   max_retries => 1,

   http => my $http = Test::Async::HTTP->new,
   access_key => 'ABCDEFGHIJKLMNOPQRST',
   secret_key => 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLOP',
);

$loop->add( $s3 );

ok( defined $s3, 'defined $s3' );
isa_ok( $s3, "Net::Async::Webservice::S3", '$s3' );

# list_bucket
{
   $time = 1369587977; # when I happened to write this test

   my $f = $s3->list_bucket(
      bucket => "bucket",
      prefix => "",
      delimiter => "/",
   );

   my $p;
   wait_for { $p = $http->next_pending or $f->is_ready };
   $f->get if $f->is_ready and $f->failure;

   my $req = $p->request;
   is( $req->method, "GET", '$req->method' );
   is( $req->uri, "https://bucket.s3.amazonaws.com/?delimiter=%2F&max-keys=1000&prefix=", '$req->uri' );

   # Assert the date header, as auth depends on it
   is( $req->header( "Date" ), "Sun, 26 May 2013 17:06:17 GMT", '$req->header("Date")' );

   is( $req->authorization,
       "AWS ABCDEFGHIJKLMNOPQRST:L0A3s2Ks+IdDGuW9NNad5iIsKn4=",
       '$req->authorization' );

   $p->respond(
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

   is( scalar $f->failure, undef, '$f is done with no failure' );
}

# put_object
{
   my $f = $s3->put_object(
      bucket => "bucket",
      key    => "key",
      value  => "value",
      meta   => {
         Name   => "Value",
      },
   );

   my $p;
   wait_for { $p = $http->next_pending };

   my $req = $p->request;
   is( $req->method, "PUT", '$req->method' );
   is( $req->uri, "https://bucket.s3.amazonaws.com/key", '$req->uri' );

   # Assert the date header, as auth depends on it
   is( $req->header( "Date" ), "Sun, 26 May 2013 17:06:17 GMT", '$req->header("Date")' );

   is( $req->authorization,
       "AWS ABCDEFGHIJKLMNOPQRST:g5JHKddLnz+80yOroYNnvSogWIY=",
       '$req->authorization' );

   my $md5 = md5_hex( $req->content );

   $p->respond(
      HTTP::Response->new( 200, "OK", [
         Etag => qq("$md5"),
      ], '' )
   );

   wait_for { $f->is_ready };

   is( scalar $f->failure, undef, '$f is done with no failure' );
}

done_testing;
