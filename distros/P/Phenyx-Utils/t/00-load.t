#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Phenyx::Utils' );
}

diag( "Testing Phenyx::Utils $Phenyx::Utils::VERSION, Perl $], $^X" );
