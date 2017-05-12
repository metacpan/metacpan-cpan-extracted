#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Sub::Called' );
}

diag( "Testing Sub::Called $Sub::Called::VERSION, Perl $], $^X" );
