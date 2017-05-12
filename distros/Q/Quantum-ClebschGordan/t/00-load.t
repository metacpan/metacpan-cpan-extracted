#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Quantum::ClebschGordan' );
}

diag( "Testing Quantum::ClebschGordan $Quantum::ClebschGordan::VERSION, Perl $], $^X" );
