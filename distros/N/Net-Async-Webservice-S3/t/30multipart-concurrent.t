#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use t::TestHTTP;

use IO::Async::Test;
use IO::Async::Loop;
use Digest::MD5 qw( md5_hex );

use HTTP::Response;

use Net::Async::Webservice::S3;

my $loop = IO::Async::Loop->new;
testing_loop( $loop );

my $s3 = Net::Async::Webservice::S3->new(
   max_retries => 1,
   http => my $http = TestHTTP->new( concurrent => 1 ),
   access_key => 'K'x20,
   secret_key => 's'x40,
);

$loop->add( $s3 );

sub await_multipart_initiate_and_respond
{
   my ( $key ) = @_;

   my $req;
   wait_for { $req = $http->pending_request };

   is( $req->method,         "POST",                    "Initiate request method for $key" );
   is( $req->uri->authority, "bucket.s3.amazonaws.com", "Initiate request URI authority for $key" );
   is( $req->uri->path,      "/$key",                   "Initiate request URI path for $key" );
   is( $req->uri->query,     "uploads",                 "Initiate request URI query for $key" );

   # Technically this isn't a valid S3 UploadId but nothing checks the
   # formatting so it's probably OK
   $http->respond(
      HTTP::Response->new( 200, "OK", [
         Content_Type => "application/xml",
      ], <<"EOF" )
<?xml version="1.0" encoding="UTF-8"?>
<InitiateMultipartUploadResult xmlns="http://s3.amazonaws.com/doc/2006-03-01/">
  <Bucket>bucket</Bucket>
  <Key>$key</Key>
  <UploadId>ABCDEFG</UploadId>
</InitiateMultipartUploadResult>
EOF
   );

   return ( $req );
}

sub await_multipart_complete_and_respond
{
   my ( $key, $want_etags ) = @_;

   my $req;
   wait_for { $req = $http->pending_request };

   is( $req->method,         "POST",                    "Complete request method for $key" );
   is( $req->uri->authority, "bucket.s3.amazonaws.com", "Complete request URI authority for $key" );
   is( $req->uri->path,      "/$key",                   "Complete request URI path for $key" );
   is( $req->uri->query,     "uploadId=ABCDEFG",        "Complete request URI query for $key" );

   is( $req->content_length, length( $req->content ), "Complete request has Content-Length" );
   like( $req->header( "Content-MD5" ), qr/^[0-9A-Z+\/]{22}==$/i,
      "Complete request has valid Base64-encoded MD5 sum" );

   my $libxml = XML::LibXML->new;
   my $xpc = XML::LibXML::XPathContext->new( $libxml->parse_string( $req->content ) );
   my %got_etags;
   foreach my $n ( $xpc->findnodes( "/CompleteMultipartUpload/Part" ) ) {
      $got_etags{$xpc->findvalue( "./PartNumber", $n )} = $xpc->findvalue( "./ETag", $n );
   }
   is_deeply( \%got_etags, $want_etags, "Complete request body etags for $key" ) if $want_etags;

   $http->respond(
      HTTP::Response->new( 200, "OK", [
         Content_Type => "application/xml",
      ], <<"EOF" )
<?xml version="1.0" encoding="UTF-8"?>
<CompleteMultipartUploadResult xmlns="http://s3.amazonaws.com/doc/2006-03-01/">
  <Location>http://bucket.s3.amazonaws.com/three</Location>
  <Bucket>bucket</Bucket>
  <Key>$key</Key>
  <ETag>"3858f62230ac3c915f300c664312c11f-2"</ETag>
</CompleteMultipartUploadResult>
EOF
   );

   return ( $req );
}

# ->put with concurrency
{
   my @parts = map { "This is part $_" } 1 .. 4;

   my @written;
   my $f = $s3->put_object(
      bucket => "bucket",
      key    => "ten",
      gen_parts => sub { return unless @parts; shift @parts },
      on_write => sub { push @written, $_[0] },
      concurrent => 3,
   );
   $f->on_fail( sub { $f->get } );

   await_multipart_initiate_and_respond "ten";

   my @p;
   wait_for { push @p, $_ while $_ = $http->next_pending; @p == 3 };

   pass( 'Got 3 concurrent upload requests' );

   foreach my $p ( @p ) {
      my $req = $p->request;
      $p->_pull_content( $p->content );

      is( $req->method,   "PUT", "Part request method for ten" );
      is( $req->uri->path, "/ten", "Part request URI path for ten" );

      my $md5 = md5_hex( $req->content );

      $p->respond( HTTP::Response->new( 200, "OK", [
         ETag => qq("$md5"),
      ], "" ) );
   }

   undef @p;
   wait_for { push @p, $_ while $_ = $http->next_pending; @p == 1 };

   pass( 'Got final upload request' );

   foreach my $p ( @p ) {
      my $req = $p->request;
      $p->_pull_content( $p->content );

      is( $req->method,   "PUT", "Part request method for ten" );
      is( $req->uri->path, "/ten", "Part request URI path for ten" );

      my $md5 = md5_hex( $req->content );

      $p->respond( HTTP::Response->new( 200, "OK", [
         ETag => qq("$md5"),
      ], "" ) );
   }

   await_multipart_complete_and_respond "ten",
      {
         1 => '"5e232f912939291d5b8aaf43d64f266a"',
         2 => '"f4709fbf099758d93ffca4951e28a7db"',
         3 => '"e3b2f586678b35726135ab3c49875d3f"',
         4 => '"0ab0fc83aa65127e94433e8cadeb3974"',
      };

   wait_for { $f->is_ready };

   my ( $etag, $len ) = $f->get;
   is( $etag, '"3858f62230ac3c915f300c664312c11f-2"', 'result of multipart put' );
   is( $len, 56, '$length of multipart put' );
}

done_testing;
