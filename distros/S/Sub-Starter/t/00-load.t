#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Sub::Starter' );
}

diag( "Testing Sub::Starter $Sub::Starter::VERSION, Perl $], $^X" );
