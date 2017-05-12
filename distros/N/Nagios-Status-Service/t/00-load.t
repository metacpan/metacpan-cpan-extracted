#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Nagios::Status::Service' );
}

diag( "Testing Nagios::Status::Service $Nagios::Status::Service::VERSION, Perl $], $^X" );
