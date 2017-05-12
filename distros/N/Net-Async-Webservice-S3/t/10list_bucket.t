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

# Simple list
{
   my $f = $s3->list_bucket(
      bucket => "bucket",
      prefix => "",
      delimiter => "/",
   );

   my $req;
   wait_for { $req = $http->pending_request or $f->is_ready };
   $f->get if $f->is_ready and $f->failure;

   is( $req->method,         "GET",                     'Request method' );
   is( $req->uri->authority, "bucket.s3.amazonaws.com", 'Request URI authority' );
   is( $req->uri->path,      "/",                       'Request URI path' );
   is_deeply( [ $req->uri->query_form ],
              [ delimiter  => "/",
                'max-keys' => 1000,
                prefix     => "" ],
              'Request URI query parameters' );

   $http->respond(
      HTTP::Response->new( 200, "OK", [
         Content_Type => "application/xml",
      ], <<'EOF' )
<?xml version="1.0" encoding="UTF-8"?>
<ListBucketResult xmlns="http://s3.amazonaws.com/doc/2006-03-01/">
  <Name>bucket</Name>
  <Prefix></Prefix>
  <Marker></Marker>
  <MaxKeys>1000</MaxKeys>
  <Delimiter>/</Delimiter>
  <IsTruncated>false</IsTruncated>

  <Contents>
    <Key>one</Key>
    <LastModified>2013-05-27T00:58:50.000Z</LastModified>
    <ETag>&quot;5f4af733fd99d974d92cd7e8d4efdf9f&quot;</ETag>
    <Size>16</Size>
    <StorageClass>STANDARD</StorageClass>
  </Contents>

  <CommonPrefixes>
    <Prefix>foo/</Prefix>
  </CommonPrefixes>
  <CommonPrefixes>
    <Prefix>bar/</Prefix>
  </CommonPrefixes>
</ListBucketResult>
EOF
   );

   wait_for { $f->is_ready };

   my ( $keys, $prefixes ) = $f->get;

   is_deeply( $keys,
              [ {
                    key => "one",
                    last_modified => "2013-05-27T00:58:50.000Z",
                    etag => '"5f4af733fd99d974d92cd7e8d4efdf9f"',
                    size => 16,
                    storage_class => "STANDARD",
                 } ],
              'list_bucket keys' );

   is_deeply( $prefixes,
              [ qw(
                  foo/
                  bar/
                ) ],
              'list_bucket prefixes' );
}

# List continuation
{
   my $f = $s3->list_bucket(
      bucket => "bucket",
      prefix => "",
      delimiter => "/",
   );

   my $req;
   wait_for { $req = $http->pending_request or $f->is_ready };
   $f->get if $f->is_ready and $f->failure;

   is( $req->method,         "GET",                     'Request method' );
   is( $req->uri->authority, "bucket.s3.amazonaws.com", 'Request URI authority' );
   is( $req->uri->path,      "/",                       'Request URI path' );
   is_deeply( [ $req->uri->query_form ],
              [ delimiter  => "/",
                'max-keys' => 1000,
                prefix     => "" ],
              'Request URI query parameters' );

   $http->respond(
      HTTP::Response->new( 200, "OK", [
         Content_Type => "application/xml",
      ], <<'EOF' )
<?xml version="1.0" encoding="UTF-8"?>
<ListBucketResult xmlns="http://s3.amazonaws.com/doc/2006-03-01/">
  <Name>bucket</Name>
  <Prefix></Prefix>
  <Marker></Marker>
  <MaxKeys>1000</MaxKeys>
  <Delimiter>/</Delimiter>
  <IsTruncated>true</IsTruncated>

  <Contents>
    <Key>one</Key>
    <LastModified>2013-05-27T00:58:50.000Z</LastModified>
    <ETag>&quot;5f4af733fd99d974d92cd7e8d4efdf9f&quot;</ETag>
    <Size>16</Size>
    <StorageClass>STANDARD</StorageClass>
  </Contents>
</ListBucketResult>
EOF
   );

   wait_for { $req = $http->pending_request or $f->is_ready };
   $f->get if $f->is_ready and $f->failure;

   is( $req->method,         "GET",                     'Request part2 method' );
   is( $req->uri->authority, "bucket.s3.amazonaws.com", 'Request part2 URI authority' );
   is( $req->uri->path,      "/",                       'Request part2 URI path' );
   is_deeply( [ $req->uri->query_form ],
              [ delimiter  => "/",
                marker     => "one",
                'max-keys' => 1000,
                prefix     => "" ],
              'Request part2 URI query parameters' );

   $http->respond(
      HTTP::Response->new( 200, "OK", [
         Content_Type => "application/xml",
      ], <<'EOF' )
<?xml version="1.0" encoding="UTF-8"?>
<ListBucketResult xmlns="http://s3.amazonaws.com/doc/2006-03-01/">
  <Name>bucket</Name>
  <Prefix></Prefix>
  <Marker></Marker>
  <MaxKeys>1000</MaxKeys>
  <Delimiter>/</Delimiter>
  <IsTruncated>false</IsTruncated>

  <Contents>
    <Key>two</Key>
    <LastModified>2013-05-27T02:40:38.000Z</LastModified>
    <ETag>&quot;5f4af733fd99d974d92cd7e8d4efdf9f&quot;</ETag>
    <Size>16</Size>
    <StorageClass>STANDARD</StorageClass>
  </Contents>
</ListBucketResult>
EOF
   );

   wait_for { $f->is_ready };

   my ( $keys ) = $f->get;

   is_deeply( $keys,
              [ {
                    key => "one",
                    last_modified => "2013-05-27T00:58:50.000Z",
                    etag => '"5f4af733fd99d974d92cd7e8d4efdf9f"',
                    size => 16,
                    storage_class => "STANDARD",
                 },
                {
                    key => "two",
                    last_modified => "2013-05-27T02:40:38.000Z",
                    etag => '"5f4af733fd99d974d92cd7e8d4efdf9f"',
                    size => 16,
                    storage_class => "STANDARD",
                 } ],
              'list_bucket keys from continued response' );
}

# List with implied bucket and prefix
{
   $s3->configure(
      bucket => "bucket",
      prefix => "subdir/",
   );

   my $f = $s3->list_bucket(
      delimiter => "/",
   );

   my $req;
   wait_for { $req = $http->pending_request or $f->is_ready };
   $f->get if $f->is_ready and $f->failure;

   is( $req->method,         "GET",                     'Request method' );
   is( $req->uri->authority, "bucket.s3.amazonaws.com", 'Request URI authority' );
   is( $req->uri->path,      "/",                       'Request URI path' );
   is_deeply( [ $req->uri->query_form ],
              [ delimiter  => "/",
                'max-keys' => 1000,
                prefix     => "subdir/" ],
              'Request URI query parameters' );

   $http->respond(
      HTTP::Response->new( 200, "OK", [
         Content_Type => "application/xml",
      ], <<'EOF' )
<?xml version="1.0" encoding="UTF-8"?>
<ListBucketResult xmlns="http://s3.amazonaws.com/doc/2006-03-01/">
  <Name>bucket</Name>
  <Prefix>subdir/</Prefix>
  <Marker></Marker>
  <MaxKeys>1000</MaxKeys>
  <Delimiter>/</Delimiter>
  <IsTruncated>false</IsTruncated>

  <Contents>
    <Key>subdir/A</Key>
    <LastModified>2013-05-27T00:58:50.000Z</LastModified>
    <ETag>&quot;5f4af733fd99d974d92cd7e8d4efdf9f&quot;</ETag>
    <Size>16</Size>
    <StorageClass>STANDARD</StorageClass>
  </Contents>

  <CommonPrefixes>
    <Prefix>subdir/1/</Prefix>
  </CommonPrefixes>
  <CommonPrefixes>
    <Prefix>subdir/2/</Prefix>
  </CommonPrefixes>
</ListBucketResult>
EOF
   );

   wait_for { $f->is_ready };

   my ( $keys, $prefixes ) = $f->get;

   is_deeply( $keys,
              [ {
                    key => "A",
                    last_modified => "2013-05-27T00:58:50.000Z",
                    etag => '"5f4af733fd99d974d92cd7e8d4efdf9f"',
                    size => 16,
                    storage_class => "STANDARD",
                 } ],
              'list_bucket keys' );
}

# Test that timeout argument is set
{
   my $f;
   my $req;

   $s3->configure( timeout => 10 );
   $f = $s3->list_bucket(
      delimiter => "/",
   );

   wait_for { $req = $http->pending_request or $f->is_ready };
   $f->get if $f->is_ready and $f->failure;

   is( $req->header( "X-NaHTTP-Timeout" ), 10, 'Request has timeout set for configured' );
   $http->respond( HTTP::Response->new( 200, "OK", [], <<'EOF' ) );
<?xml version="1.0" encoding="UTF-8"?>
<ListBucketResult/>
EOF

   $f = $s3->list_bucket(
      delimiter => "/",
      timeout => 20,
   );

   wait_for { $req = $http->pending_request or $f->is_ready };
   $f->get if $f->is_ready and $f->failure;

   is( $req->header( "X-NaHTTP-Timeout" ), 20, 'Request has timeout set for immediate' );
   $http->respond( HTTP::Response->new( 200, "OK", [], <<'EOF' ) );
<?xml version="1.0" encoding="UTF-8"?>
<ListBucketResult/>
EOF
}

done_testing;
