#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Nagios::Status::HostStatus' );
}

diag( "Testing Nagios::Status::HostStatus $Nagios::Status::HostStatus::VERSION, Perl $], $^X" );
