#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Nagios::Status::Host' );
}

diag( "Testing Nagios::Status::Host $Nagios::Status::Host::VERSION, Perl $], $^X" );
