#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'SNMP::MibProxy' );
}

diag( "Testing SNMP::MibProxy $SNMP::MibProxy::VERSION, Perl $], $^X" );
