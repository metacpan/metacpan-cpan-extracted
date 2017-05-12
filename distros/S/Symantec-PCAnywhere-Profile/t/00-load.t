#!perl -T

use Test::More tests => 3;

BEGIN {
	use_ok( 'Symantec::PCAnywhere::Profile' );
	use_ok( 'Symantec::PCAnywhere::Profile::CHF' );
	use_ok( 'Symantec::PCAnywhere::Profile::CIF' );
}

diag( "Testing Symantec::PCAnywhere::Profile $Symantec::PCAnywhere::Profile::VERSION, Perl $], $^X" );
