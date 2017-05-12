#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Net::SNMP::Util' ) || print "Bail out!
";
}

diag( "Testing Net::SNMP::Util $Net::SNMP::Util::VERSION, Perl $], $^X" );

# Well, Since all of computer does not implement SNMP agent service,
# so, there are no test to check SNMP operations...
