#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'SNMP::Agent' ) || print "Bail out!
";
}

diag( "Testing SNMP::Agent $SNMP::Agent::VERSION, Perl $], $^X" );
