#!/usr/bin/perl -w

use strict;
use lib 't/lib';

use Test::More tests => 8;
use Test::HexString;

use IO::Async::Loop;
use IO::Async::Test;

use Net::Async::FastCGI;

use TestFCGI;

my $request;

my ( $S, $selfaddr ) = make_server_sock;

my $loop = IO::Async::Loop->new();
testing_loop( $loop );

my $fcgi = Net::Async::FastCGI->new(
   handle => $S,
   on_request => sub { $request = $_[1] },
);

$loop->add( $fcgi );

my $C = connect_client_sock( $selfaddr );

$C->syswrite(
   # Begin
   fcgi_trans( type => 1, id => 1, data => "\0\1\0\0\0\0\0\0" ) .
   # Parameters
   fcgi_trans( type => 4, id => 1, data => 
      fcgi_keyval( REQUEST_METHOD  => "GET" ) .
      fcgi_keyval( SCRIPT_NAME     => "/fcgi-bin/test.fcgi" ) .
      fcgi_keyval( PATH_INFO       => "/path/to/file" ) .
      fcgi_keyval( QUERY_STRING    => "" ) .
      fcgi_keyval( HTTP_HOST       => "mysite" ) .
      fcgi_keyval( CONTENT_TYPE    => "text/plain" ) .
      fcgi_keyval( CONTENT_LENGTH  => "11" ) .
      fcgi_keyval( SERVER_HOST     => "localhost" ) .
      fcgi_keyval( SERVER_PORT     => "80" ) .
      fcgi_keyval( SERVER_PROTOCOL => "HTTP/1.1" ) .
      fcgi_keyval( "" => "" )
   ) .
   # End of parameters
   fcgi_trans( type => 4, id => 1, data => "" ) .
   # STDIN
   fcgi_trans( type => 5, id => 1, data => "Hello there" ) .
   # End of STDIN
   fcgi_trans( type => 5, id => 1, data => "" )
);

wait_for { defined $request };

my $httpreq = $request->as_http_request;

isa_ok( $httpreq, 'HTTP::Request', '$httpreq isa HTTP::Request' );

is( $httpreq->method,           "GET",         '$httpreq->method' );
is( $httpreq->protocol,         "HTTP/1.1",    '$httpreq->protocol' );
is( $httpreq->header( "Host" ), "mysite",      '$httpreq->header' );
is( $httpreq->content_type,     "text/plain",  '$httpreq->content_type' );
is( $httpreq->content,          "Hello there", '$httpreq->content' );

is( $httpreq->uri, "http://mysite/fcgi-bin/test.fcgi/path/to/file", '$httpreq->uri' );

require HTTP::Response;
my $resp = HTTP::Response->new( 200 );
# TODO: Maybe we can get Net::Async::FastCGI::Request itself to fill this in?
$resp->protocol( "HTTP/1.1" );
$resp->header( Content_type => "text/plain" );
$resp->content( "Here is my response" );

$request->send_http_response( $resp );

my $CRLF = "\x0d\x0a";
my $expect_stdout = join( "", map "$_$CRLF",
      "HTTP/1.1 200 OK",
      "Content-Type: text/plain",
      "Status: 200",
      '' ) .
   "Here is my response";

my $expect;

$expect =
   # STDOUT
   fcgi_trans( type => 6, id => 1, data => $expect_stdout ) .
   # End of STDOUT
   fcgi_trans( type => 6, id => 1, data => "" ) .
   # End request
   fcgi_trans( type => 3, id => 1, data => "\0\0\0\0\0\0\0\0" );

my $buffer;

$buffer = "";

wait_for_stream { length $buffer >= length $expect } $C => $buffer;

is_hexstr( $buffer, $expect, 'FastCGI end request record' );
