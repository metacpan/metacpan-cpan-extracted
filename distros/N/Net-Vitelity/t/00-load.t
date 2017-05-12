#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Net::Vitelity' );
}

diag( "Testing Net::Vitelity $Net::Vitelity::VERSION, Perl $], $^X" );
