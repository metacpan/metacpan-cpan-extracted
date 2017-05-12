#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Nagios::Downtime' );
}

diag( "Testing Nagios::Downtime $Nagios::Downtime::VERSION, Perl $], $^X" );
