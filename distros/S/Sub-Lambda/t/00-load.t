#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Sub::Lambda' );
}

diag( "Testing Sub::Lambda $Sub::Lambda::VERSION, Perl $], $^X" );
