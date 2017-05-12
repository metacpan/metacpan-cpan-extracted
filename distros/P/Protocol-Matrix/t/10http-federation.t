#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

use Protocol::Matrix::HTTP::Federation;

my $fed = Protocol::Matrix::HTTP::Federation->new;

ok( defined $fed, '$fed defined' );
isa_ok( $fed, "Protocol::Matrix::HTTP::Federation", '$fed' );

# make_key_v1_request
{
   my $req = $fed->make_key_v1_request(
      server_name => "destination",
   );

   ok( defined $req, '$req defined for ->make_key_v1_request' );
   isa_ok( $req, "HTTP::Request", '$req for ->make_key_v1_request' );

   is( $req->method, "GET", '$req->method' );
   is( $req->uri->path, "/_matrix/key/v1", '$req->uri->path' );
   is( $req->header( "Host" ), "destination", '$req->header( "Host" )' );
}

{
   my $req = $fed->make_key_v2_server_request(
      server_name => "destination",
      key_id      => "ed25519:20150805",
   );

   is( $req->uri->path, "/_matrix/key/v2/server/ed25519:20150805", '$req->uri->path' );
}

done_testing;
