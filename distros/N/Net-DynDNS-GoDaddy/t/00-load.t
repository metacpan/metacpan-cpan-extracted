#!perl
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Net::DynDNS::GoDaddy' ) || print "Bail out!\n";
}

diag( "Testing Net::DynDNS::GoDaddy $Net::DynDNS::GoDaddy::VERSION, Perl $], $^X" );
