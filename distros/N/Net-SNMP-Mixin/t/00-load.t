#!perl -T

use Test::More tests => 3;

BEGIN {
	use_ok( 'Net::SNMP::Mixin' );
	use_ok( 'Net::SNMP::Mixin::Util' );
	use_ok( 'Net::SNMP::Mixin::System' );
}

