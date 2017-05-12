#!/usr/bin/perl -w

use strict;
use lib 't/lib';

use Test::More tests => 6;
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
   # Begin with FCGI_KEEP_CONN
   fcgi_trans( type => 1, id => 1, data => "\0\1\1\0\0\0\0\0" ) .
   # Parameters
   fcgi_trans( type => 4, id => 1, data => "\4\5NAMEfirst" ) .
   # End of parameters
   fcgi_trans( type => 4, id => 1, data => "" ) .
   # No STDIN
   fcgi_trans( type => 5, id => 1, data => "" )
);

wait_for { defined $request };

is_deeply( $request->params,
           { NAME => 'first' },
           '$request params' );
is( $request->read_stdin_line,
    undef,
    '$request has empty STDIN' );

$request->print_stdout( "one" );
$request->finish;

my $expect;

$expect =
   # STDOUT
   fcgi_trans( type => 6, id => 1, data => "one" ) .
   # End of STDOUT
   fcgi_trans( type => 6, id => 1, data => "" ) .
   # End request
   fcgi_trans( type => 3, id => 1, data => "\0\0\0\0\0\0\0\0" );

my $buffer;

$buffer = "";

wait_for_stream { length $buffer >= length $expect } $C => $buffer;

is_hexstr( $buffer, $expect, 'FastCGI end request record' );

# Now send a second one
$C->syswrite(
   # Begin with FCGI_KEEP_CONN
   fcgi_trans( type => 1, id => 1, data => "\0\1\1\0\0\0\0\0" ) .
   # Parameters
   fcgi_trans( type => 4, id => 1, data => "\4\6NAMEsecond" ) .
   # End of parameters
   fcgi_trans( type => 4, id => 1, data => "" ) .
   # No STDIN
   fcgi_trans( type => 5, id => 1, data => "" )
);

undef $request;
wait_for { defined $request };

is_deeply( $request->params,
           { NAME => 'second' },
           '$request params' );
is( $request->read_stdin_line,
    undef,
    '$req has empty STDIN' );

$request->print_stdout( "two" );
$request->finish;

$expect =
   # STDOUT
   fcgi_trans( type => 6, id => 1, data => "two" ) .
   # End of STDOUT
   fcgi_trans( type => 6, id => 1, data => "" ) .
   # End request
   fcgi_trans( type => 3, id => 1, data => "\0\0\0\0\0\0\0\0" );

$buffer = "";

wait_for_stream { length $buffer >= length $expect } $C => $buffer;

is_hexstr( $buffer, $expect, 'FastCGI end request record' );
