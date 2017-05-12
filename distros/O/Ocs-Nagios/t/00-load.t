#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Ocs::Nagios' );
}

diag( "Testing Ocs::Nagios $Ocs::Nagios::VERSION, Perl $], $^X" );
