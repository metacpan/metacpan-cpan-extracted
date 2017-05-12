#!perl -T

use Test::More tests => 4;

BEGIN {
	use_ok( 'SNMP::Class' );
	use_ok( 'SNMP::Class::ResultSet' );
	use_ok( 'SNMP::Class::OID' );
	use_ok( 'SNMP::Class::Varbind' );
}

diag( "Testing SNMP::Class $SNMP::Class::VERSION, Perl $], $^X" );
