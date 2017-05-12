#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Statistics::FisherPitman' );
}

diag( "Testing Statistics::FisherPitman $Statistics::FisherPitman::VERSION, Perl $], $^X" );
