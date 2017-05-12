#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Sunpower::Cryocooler' );
}

diag( "Testing Sunpower::Cryocooler $Sunpower::Cryocooler::VERSION, Perl $], $^X" );
