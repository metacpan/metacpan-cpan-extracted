#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Object::Enum' );
}

diag( "Testing Object::Enum $Object::Enum::VERSION, Perl $], $^X" );
