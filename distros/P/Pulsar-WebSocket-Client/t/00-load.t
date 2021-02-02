#!perl
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Pulsar::WebSocket::Client' ) || print "Bail out!\n";
}

diag( "Testing Pulsar::WebSocket::Client $Pulsar::WebSocket::Client::VERSION, Perl $], $^X" );
