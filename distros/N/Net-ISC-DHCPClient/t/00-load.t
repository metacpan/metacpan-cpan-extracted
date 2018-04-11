#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Net::ISC::DHCPClient' ) || print "Bail out!\n";
}

diag( "Testing Net::ISC::DHCPClient $Net::ISC::DHCPClient::VERSION, Perl $], $^X" );
