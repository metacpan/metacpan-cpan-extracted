#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Net::DHCP::Info' );
}

diag( "Testing Net::DHCP::Info $Net::DHCP::Info::VERSION, Perl $], $^X" );
