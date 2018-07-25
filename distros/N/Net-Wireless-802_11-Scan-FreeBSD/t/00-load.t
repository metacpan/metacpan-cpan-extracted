#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Net::Wireless::802_11::Scan::FreeBSD' ) || print "Bail out!\n";
}

diag( "Testing Net::Wireless::802_11::Scan::FreeBSD $Net::Wireless::802_11::Scan::FreeBSD::VERSION, Perl $], $^X" );
