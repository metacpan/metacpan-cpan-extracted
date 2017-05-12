#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Sub::Methodical' );
}

diag( "Testing Sub::Methodical $Sub::Methodical::VERSION, Perl $], $^X" );
