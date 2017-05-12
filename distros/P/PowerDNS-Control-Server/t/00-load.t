#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'PowerDNS::Control::Server' );
}

diag( "Testing PowerDNS::Control::Server $PowerDNS::Control::Server::VERSION, Perl $], $^X" );
