#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Path::Abstract' );
}

diag( "Testing Path::Abstract $Path::Abstract::VERSION, Perl $], $^X" );
