#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'String::Unique' );
}

diag( "Testing String::Unique $String::Unique::VERSION, Perl $], $^X" );
