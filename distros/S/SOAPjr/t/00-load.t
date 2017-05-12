#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'SOAPjr' );
}

diag( "Testing SOAPjr $SOAPjr::VERSION, Perl $], $^X" );
