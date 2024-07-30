#!/usr/bin/perl

use v5.14;
use warnings;

use lib 't/lib';

use Test2::V0;

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
   # Some unknown value
   fcgi_trans( type => 0x14, id => 0, data => "" )
);
my $expect;

$expect =
   # FCGI_UNKNOWN_TYPE
   fcgi_trans( type => 11, id => 0, data => "\x14\0\0\0\0\0\0\0" );

my $buffer;

$buffer = "";

wait_for_stream { length $buffer >= length $expect } $C => $buffer;

is( $buffer, $expect, 'FastCGI unknown type' );

$C->syswrite(
   # Begin
   fcgi_trans( type => 1, id => 1, data => "\0\4\0\0\0\0\0\0" )
);

$expect =
   # End request
   fcgi_trans( type => 3, id => 1, data => "\0\0\0\0\3\0\0\0" );

$buffer = "";

wait_for_stream { length $buffer >= length $expect } $C => $buffer;

is( $buffer, $expect, "FastCGI end request record with unknown role" );

done_testing;
