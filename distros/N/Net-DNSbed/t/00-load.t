#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Net::DNSbed' ) || print "Bail out!\n";
}

diag( "Testing Net::DNSbed $Net::DNSbed::VERSION, Perl $], $^X" );
