#!/usr/bin/perl -w

use strict;
use lib 't/lib';

use Test::More tests => 7;
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
   fcgi_trans( type => 4, id => 1, data => "\3\3FOOfoo\5\5SPLOTsplot" ) .
   # End of parameters
   fcgi_trans( type => 4, id => 1, data => "" ) .
   # STDIN
   fcgi_trans( type => 5, id => 1, data => "Some data on STDIN\nAnd another line\n" ) .
   # End of STDIN
   fcgi_trans( type => 5, id => 1, data => "" )
);

wait_for { defined $request };

my $stdin = $request->stdin;

ok( defined $stdin, '$request->stdin defined' );

is( <$stdin>, "Some data on STDIN\n", '<$stdin>' );

is( read( $stdin, my $readbuf, 8192 ), 17, 'read $stdin length' );
is( $readbuf, "And another line\n",        'read $stdin buffer' );

my $stdout = $request->stdout;

ok( defined $stdout, '$request->stdout defined' );
print $stdout "Hello, world!";

my $stderr = $request->stderr;

ok( defined $stderr, '$request->stderr defined' );
print $stderr "Some errors occured\n";

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
