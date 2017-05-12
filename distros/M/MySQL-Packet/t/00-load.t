#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'MySQL::Packet' );
}

diag( "Testing MySQL::Packet $MySQL::Packet::VERSION, Perl $], $^X" );
