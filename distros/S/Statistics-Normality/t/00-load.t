#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Statistics::Normality' );
}

diag( "Testing Statistics::Normality $Statistics::Normality::VERSION, Perl $], $^X" );
