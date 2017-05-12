#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Net::YASA' );
}

diag( "Testing Net::YASA $Net::YASA::VERSION, Perl $], $^X" );
