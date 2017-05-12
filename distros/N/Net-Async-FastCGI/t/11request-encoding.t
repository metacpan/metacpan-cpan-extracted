#!/usr/bin/perl -w

use strict;
use lib 't/lib';

use Test::More tests => 5;
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
   # No parameters
   fcgi_trans( type => 4, id => 1, data => "" ) .
   # STDIN
   fcgi_trans( type => 5, id => 1, data => "\xc3\xa5" ) .
   # End of STDIN
   fcgi_trans( type => 5, id => 1, data => "" )
);

wait_for { defined $request };

is_deeply( $request->params,
           {},
           '$request has empty params hash' );
is( $request->read_stdin_line,
    chr(0xe5),
    '$request has a single Unicode character' );

# Pick a character in 8859-1 so we can check UTF-8 is really being applied
$request->print_stdout( chr(0xe4) );

my $expect;

$expect =
   # STDOUT
   fcgi_trans( type => 6, id => 1, data => "\xc3\xa4" );

my $buffer;

$buffer = "";

wait_for_stream { length $buffer >= length $expect } $C => $buffer;

is_hexstr( $buffer, $expect, 'FastCGI STDOUT stream contains UTF-8 encoded data' );

$request->set_encoding( "ISO-8859-1" );

$request->print_stdout( chr(0xe4) );
$request->finish;

$expect =
   # STDOUT
   fcgi_trans( type => 6, id => 1, data => "\xe4" ) .
   # End of STDOUT
   fcgi_trans( type => 6, id => 1, data => "" ) .
   # End request
   fcgi_trans( type => 3, id => 1, data => "\0\0\0\0\0\0\0\0" );

$buffer = "";

wait_for_stream { length $buffer >= length $expect } $C => $buffer;

is_hexstr( $buffer, $expect, 'FastCGI end request record contains ISO-8859-1 data' );

# Since we didn't specify FCGI_KEEP_CONN, we expect that $C should now be
# closed, and that reading any more will give us EOF

my $l = $C->sysread( $buffer, 8192 );
is( $l, 0, 'Client connection now closed' );
