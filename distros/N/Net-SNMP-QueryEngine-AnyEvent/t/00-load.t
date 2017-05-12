#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Net::SNMP::QueryEngine::AnyEvent' ) || print "Bail out!\n";
}

diag( "Testing Net::SNMP::QueryEngine::AnyEvent $Net::SNMP::QueryEngine::AnyEvent::VERSION, Perl $], $^X" );
