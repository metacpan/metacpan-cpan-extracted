#!/usr/bin/perl

use v5.14;
use warnings;

use Test2::V0;

use Net::Prometheus;

use HTTP::Request;

my $client = Net::Prometheus->new;

$client->new_gauge(
   name => "test",
   help => "A testing gauge"
)->set( 123 );

my $request = HTTP::Request->new( GET => "http://localhost/metrics" );

my $response = $client->handle( $request );

is( $response->code, 200, '$response->code' );
is( $response->header( "Content-Type" ), "text/plain; version=0.0.4; charset=utf-8",
   '$response->header Content-Type' );
like( $response->content,
   qr/^test 123$/m,
   'Response contains metrics' );
ok( $response->content_length, '$response->content_length' );

done_testing;
