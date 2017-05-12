#!perl

use Test::More tests => 1;

BEGIN {
    use_ok( 'Net::SNMP::Util::OID' ) || print "Bail out!
";
}

diag( "Testing Net::SNMP::Util::OID $Net::SNMP::Util::OID::VERSION, Perl $], $^X" );
