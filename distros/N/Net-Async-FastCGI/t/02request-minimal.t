#!/usr/bin/perl -w

use strict;
use lib 't/lib';

use Test::More tests => 10;
use Test::HexString;
use Test::Refcount;

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

ok( defined $fcgi, 'defined $fcgi' );
isa_ok( $fcgi, "Net::Async::FastCGI", '$fcgi isa FCGI::Async' );

is_oneref( $fcgi, '$fcgi has refcount 1 initially' );

$loop->add( $fcgi );

is_refcount( $fcgi, 2, '$fcgi has refcount 2 after $loop->add' );

my $C = connect_client_sock( $selfaddr );

# Got it - now pretend to be an FCGI client, such as how a webserver would
# behave.

$C->syswrite(
   # Begin
   fcgi_trans( type => 1, id => 1, data => "\0\1\0\0\0\0\0\0" ) .
   # No parameters
   fcgi_trans( type => 4, id => 1, data => "" ) .
   # No STDIN
   fcgi_trans( type => 5, id => 1, data => "" )
);

wait_for { defined $request };

is_deeply( $request->params,
           {},
           '$request has empty params hash' );
is( $request->read_stdin_line,
    undef,
    '$request has empty STDIN' );

$request->finish;

undef $request; # for refcount

my $expect;

$expect =
   # End of STDOUT
   fcgi_trans( type => 6, id => 1, data => "" ) .
   # End request
   fcgi_trans( type => 3, id => 1, data => "\0\0\0\0\0\0\0\0" );

my $buffer;

$buffer = "";

wait_for_stream { length $buffer >= length $expect } $C => $buffer;

is_hexstr( $buffer, $expect, 'FastCGI end request record' );

# Since we didn't specify FCGI_KEEP_CONN, we expect that $C should now be
# closed, and that reading any more will give us EOF

my $l = $C->sysread( $buffer, 8192 );
is( $l, 0, 'Client connection now closed' );

is_refcount( $fcgi, 2, '$fcgi has refcount 2 before $loop->remove' );

$loop->remove( $fcgi );

is_oneref( $fcgi, '$fcgi has refcount 1 finally' );
