#!perl -T

use Test::More tests => 2;

BEGIN {
	use_ok( 'SNMP::LogParser' );
}

diag( "Testing SNMP::LogParser $SNMP::LogParser::VERSION, Perl $], $^X" );
use_ok( 'SNMP::LogParserDriver' );
