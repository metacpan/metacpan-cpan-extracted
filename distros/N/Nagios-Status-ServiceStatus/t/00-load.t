#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Nagios::Status::ServiceStatus' );
}

diag( "Testing Nagios::Status::ServiceStatus $Nagios::Status::ServiceStatus::VERSION, Perl $], $^X" );
