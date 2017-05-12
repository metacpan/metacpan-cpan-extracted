#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Sculptor::Date' );
}

diag( "Testing Sculptor::Date $Sculptor::Date::VERSION, Perl $], $^X" );
