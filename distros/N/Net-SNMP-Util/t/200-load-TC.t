#!perl

use Test::More tests => 1;

BEGIN {
    use_ok( 'Net::SNMP::Util::TC' ) || print "Bail out!
";
}

diag( "Testing Net::SNMP::Util::TC $Net::SNMP::Util::TC::VERSION, Perl $], $^X" );
