#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Net::Interface::Wireless::FreeBSD' );
}

diag( "Testing Net::Interface::Wireless::FreeBSD $Net::Interface::Wireless::FreeBSD::VERSION, Perl $], $^X" );
