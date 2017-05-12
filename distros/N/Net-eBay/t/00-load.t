#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Net::eBay' );
}

diag( "Testing Net::eBay $Net::eBay::VERSION, Perl $], $^X" );
