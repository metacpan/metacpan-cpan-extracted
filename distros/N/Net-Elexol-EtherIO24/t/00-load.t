#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Net::Elexol::EtherIO24' );
}

diag( "Testing Net::Elexol::EtherIO24 $Net::Elexol::EtherIO24::VERSION, Perl $], $^X" );
