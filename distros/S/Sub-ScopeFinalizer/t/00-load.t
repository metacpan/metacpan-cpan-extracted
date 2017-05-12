#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Sub::ScopeFinalizer' );
}

diag( "Testing Sub::ScopeFinalizer $Sub::ScopeFinalizer::VERSION, Perl $], $^X" );
