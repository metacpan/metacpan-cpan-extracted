#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'PowerDNS::Control::Client' );
}

diag( "Testing PowerDNS::Control::Client $PowerDNS::Control::Client::VERSION, Perl $], $^X" );
