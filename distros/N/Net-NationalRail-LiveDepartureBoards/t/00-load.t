#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Net::NationalRail::LiveDepartureBoards' );
}

diag( "Testing Net::NationalRail::LiveDepartureBoards $Net::NationalRail::LiveDepartureBoards::VERSION, Perl $], $^X" );
