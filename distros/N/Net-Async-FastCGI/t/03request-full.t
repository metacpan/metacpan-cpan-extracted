#!/usr/bin/perl -w

use strict;
use lib 't/lib';

use Test::More tests => 12;
use Test::HexString;

use IO::Async::Loop;
use IO::Async::Test;

use Net::Async::FastCGI;

use TestFCGI;

my $CRLF = "\x0d\x0a";

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
      fcgi_keyval( SCRIPT_NAME     => "/cgi-bin/foo.fcgi" ) .
      fcgi_keyval( PATH_INFO       => "/another/path" ) .
      fcgi_keyval( QUERY_STRING    => "foo=bar" ) .
      fcgi_keyval( SERVER_PROTOCOL => "HTTP/1.1" )
   ) .
   # End of parameters
   fcgi_trans( type => 4, id => 1, data => "" ) .
   # STDIN
   fcgi_trans( type => 5, id => 1, data => "Hello, FastCGI script$CRLF" . 
                                           "Here are several lines of data$CRLF" .
                                           "They should appear on STDIN$CRLF" ) .
   # End of STDIN
   fcgi_trans( type => 5, id => 1, data => "" )
);

wait_for { defined $request };

is_deeply( $request->params,
           {
              REQUEST_METHOD  => "GET",
              SCRIPT_NAME     => "/cgi-bin/foo.fcgi",
              PATH_INFO       => "/another/path",
              QUERY_STRING    => "foo=bar",
              SERVER_PROTOCOL => "HTTP/1.1",
           },
           '$request has correct params' );
is( $request->method,       "GET",                            '$request->method' );
is( $request->script_name,  "/cgi-bin/foo.fcgi",              '$request->script_name' );
is( $request->path_info,    "/another/path",                  '$request->path_info' );
is( $request->path,         "/cgi-bin/foo.fcgi/another/path", '$request->path' );
is( $request->query_string, "foo=bar",                        '$request->query_string' );
is( $request->protocol,     "HTTP/1.1",                       '$request->protocol' );

is( $request->read_stdin_line,
    "Hello, FastCGI script$CRLF",
    '$request has correct STDIN line 1' );
is( $request->read_stdin_line,
    "Here are several lines of data$CRLF",
    '$request has correct STDIN line 2' );
is( $request->read_stdin_line,
    "They should appear on STDIN$CRLF",
    '$request has correct STDIN line 3' );
is( $request->read_stdin_line,
    undef,
    '$request has correct STDIN finish' );

$request->print_stdout( "Hello, world!" );
$request->print_stderr( "Some errors occured\n" );
$request->finish( 5 );

my $expect;

$expect =
   # STDOUT
   fcgi_trans( type => 6, id => 1, data => "Hello, world!" ) .
   # STDERR
   fcgi_trans( type => 7, id => 1, data => "Some errors occured\n" ) .
   # End of STDOUT
   fcgi_trans( type => 6, id => 1, data => "" ) .
   # End of STDERR
   fcgi_trans( type => 7, id => 1, data => "" ) .
   # End request
   fcgi_trans( type => 3, id => 1, data => "\0\0\0\5\0\0\0\0" );

my $buffer;

$buffer = "";

wait_for_stream { length $buffer >= length $expect } $C => $buffer;

is_hexstr( $buffer, $expect, 'FastCGI end request record' );
