#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Number::Closest' );
}

diag( "Testing Number::Closest $Number::Closest::VERSION, Perl $], $^X" );
