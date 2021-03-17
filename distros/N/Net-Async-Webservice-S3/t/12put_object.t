#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Test::Async::HTTP;

use IO::Async::Test;
use IO::Async::Loop;
use Digest::MD5 qw( md5_hex );

use HTTP::Response;

use Net::Async::Webservice::S3;

my $loop = IO::Async::Loop->new;
testing_loop( $loop );

my $s3 = Net::Async::Webservice::S3->new(
   max_retries => 1,
   http => my $http = Test::Async::HTTP->new,
   access_key => 'K'x20,
   secret_key => 's'x40,
);

$loop->add( $s3 );

sub await_upload_and_respond
{
   my ( $key, $content ) = @_;

   my $p;
   wait_for { $p = $http->next_pending };

   my $req = $p->request;
   is( $req->method,         "PUT",                     "Request method for $key" );
   is( $req->uri->authority, "bucket.s3.amazonaws.com", "Request URI authority for $key" );
   is( $req->uri->path,      "/$key",                   "Request URI path for $key" );
   is( $req->content,        $content,                  "Request body for $key" );

   my $md5 = md5_hex( $req->content );

   $p->respond(
      HTTP::Response->new( 200, "OK", [
         ETag => qq("$md5"),
      ], "" )
   );

   return ( $req );
}

# Single PUT from string
{
   my $written;
   my $f = $s3->put_object(
      bucket => "bucket",
      key    => "one",
      value  => "a new value",
      on_write => sub { ( $written ) = @_; },
   );
   $f->on_fail( sub { die @_ } );

   await_upload_and_respond "one", "a new value";

   wait_for { $f->is_ready };

   my ( $etag, $len ) = $f->get;
   is( $etag, '"895feaa3ad7b47130e2314bd88cab3b0"', 'result of simple put' );
   is( $len, 11, '$length of simple put' );

   is( $written, 11, 'on_write indicated 11 bytes total' );
}

# Single PUT from Future->string
{
   my $f = $s3->put_object(
      bucket => "bucket",
      key    => "two",
      value  => my $value_f = Future->new,
   );
   $f->on_fail( sub { die @_ } );

   $loop->later( sub { $value_f->done( "Deferred content that came later" ) } );

   await_upload_and_respond "two", "Deferred content that came later";

   my ( $etag, $len ) = $f->get;
   is( $len, 32, '$length of put from Future' );
}

# Single PUT from CODE/size pair
{
   my $f = $s3->put_object(
      bucket => "bucket",
      key    => "three",
      value  => sub { substr( "Content from a CODE ref", $_[0], $_[1] ) },
      value_length => 23,
   );
   $f->on_fail( sub { die @_ } );

   await_upload_and_respond "three", "Content from a CODE ref";

   my ( $etag, $len ) = $f->get;
   is( $len, 23, '$length from put from CODE' );
}

# Single PUT from Future->CODE/size pair
{
   my $f = $s3->put_object(
      bucket => "bucket",
      key    => "four",
      value  => my $value_f = Future->new,
   );
   $f->on_fail( sub { die @_ } );

   $loop->later( sub { $value_f->done(
      sub { substr( "Content from a Future->CODE ref", $_[0], $_[1] ) }, 31
   ) });

   await_upload_and_respond "four", "Content from a Future->CODE ref";

   my ( $etag, $len ) = $f->get;
   is( $len, 31, '$length from put from Future->CODE' );
}

# Single PUT with extra metadata
{
   my $f = $s3->put_object(
      bucket => "bucket",
      key    => "ONE",
      value  => "the value",
      meta   => {
         A      => "a",
      },
   );
   $f->on_fail( sub { die @_ } );

   my ( $request ) = await_upload_and_respond "ONE", "the value";
   is( $request->header( "X-Amz-Meta-A" ), "a", '$request has X-Amz-Meta-A header' );

   $f->get;
}

# Test that timeout argument is set only for direct argument
{
   my $f;
   my $p;
   my $req;

   $s3->configure( timeout => 10 );
   $f = $s3->put_object(
      bucket => "bucket",
      key    => "-one-",
      value  => "a value",
   );

   wait_for { $p = $http->next_pending or $f->is_ready };
   $f->get if $f->is_ready and $f->failure;

   $req = $p->request;
   is( $req->header( "X-NaHTTP-Timeout" ), undef, 'Request has no timeout for configured' );
   $p->respond( 200, "OK", [] );

   $f = $s3->put_object(
      bucket  => "bucket",
      key     => "-one-",
      value   => "a value",
      timeout => 20,
   );

   undef $p;
   wait_for { $p = $http->next_pending or $f->is_ready };
   $f->get if $f->is_ready and $f->failure;

   $req= $p->request;
   is( $req->header( "X-NaHTTP-Timeout" ), 20, 'Request has timeout set for immediate' );
   $p->respond( 200, "OK", [] );
}

done_testing;
