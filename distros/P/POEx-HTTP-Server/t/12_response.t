#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 22;
BEGIN { 
    use_ok('POEx::HTTP::Server::Response');
    use_ok('POEx::HTTP::Server::Request');
}

my $resp = POEx::HTTP::Server::Response->new();
isa_ok( $resp, 'POEx::HTTP::Server::Response' );

is( $resp->streaming, undef(), "Streaming isn't set" );
is( $resp->streaming(1), undef(), "Streaming wasn't set" );
is( $resp->streaming, 1, "Streaming is set" );

is( $resp->headers_sent, undef(), "Header not sent" );
is( $resp->headers_sent(1), undef(), "Header wasn't sent" );
is( $resp->headers_sent, 1, "Header is sent" );

my $req = POEx::HTTP::Server::Request->new( GET => "/honk/bonk.html" );
$req->protocol( 'HTTP/1.1' );
isa_ok( $req, 'POEx::HTTP::Server::Request' );

is( $resp->request, undef(), "No request" );
$resp->request( $req );
ok( $resp->request, "Request set" );

$resp->headers_sent( 0 );
$resp->streaming( 0 );
ok( !$resp->protocol, "No protocol specified" );
$resp->__fix_headers;
ok( $resp->protocol, "Protocol now specified" );
ok( $resp->header( 'Date' ) , "Date now set" );
ok( !$resp->header( 'Content-Length' ) , "No Content-Length" );
$resp->content( 'HELLO WORLD' );
$resp->__fix_headers;
is( $resp->header( 'Content-Length' ), 11 , "Set Content-Length" );

$resp->content( 'honk bonk' );
$resp->__fix_headers;
is( $resp->header( 'Content-Length' ), 11 , "Didn't change Content-Length" );

#####
$resp = POEx::HTTP::Server::Response->new();
isa_ok( $resp, 'POEx::HTTP::Server::Response' );
$resp->request( $req );
$resp->content( 'HELLO WORLD' );
$resp->streaming( 1 );
$resp->__fix_headers;
ok( !$resp->header( 'Content-Length' ) , "No Content-Length during streaming" );

#####
$resp = POEx::HTTP::Server::Response->new();
isa_ok( $resp, 'POEx::HTTP::Server::Response' );
$req->method( 'HEAD' );
$resp->request( $req );
$resp->content( 'HELLO WORLD' );
$resp->__fix_headers;
ok( !$resp->header( 'Content-Length' ) , "No Content-Length for HEAD" );

