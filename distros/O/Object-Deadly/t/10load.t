#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Object::Deadly' );
}

diag( "Testing Object::Deadly $Object::Deadly::VERSION, Perl $], $^X" );
