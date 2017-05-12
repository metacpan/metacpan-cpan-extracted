#!perl -T

use Test::More no_plan => 1;

BEGIN {
	use_ok( 'Pikeo::API' );
	use_ok( 'Pikeo::API::Photos' );
}

diag( "Testing Pikeo::API $Pikeo::API::VERSION, Perl $], $^X" );
