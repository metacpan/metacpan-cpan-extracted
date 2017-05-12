#!perl

use Test::More tests => 3;

BEGIN {
	use_ok( 'Net::SNMP' );
	use_ok( 'Net::SNMP::Mixin' );
	use_ok( 'Net::SNMP::Mixin::CiscoDot1qVlanStaticTrunks' );
}

