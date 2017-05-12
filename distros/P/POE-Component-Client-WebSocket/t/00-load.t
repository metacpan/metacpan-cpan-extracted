#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'POE::Component::Client::WebSocket' ) || print "Bail out!\n";
}

diag( "Testing POE::Component::Client::WebSocket $POE::Component::Client::WebSocket::VERSION, Perl $], $^X" );
