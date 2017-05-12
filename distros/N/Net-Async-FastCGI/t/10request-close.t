#!/usr/bin/perl -w

use strict;
use lib 't/lib';

use Test::More tests => 4;
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

$request->print_stdout( "Hello, world!" );

# Client goes away before we finish
close $C;

wait_for { $request->is_aborted };

is( $request->is_aborted, 1, 'Request is aborted' );

$request->finish;

$loop->loop_once( 0 );

# If we're still alive here then the code didn't die. Good.
ok( 1, 'Still alive after $request->finish' );
