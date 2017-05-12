#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 3;

BEGIN {
    use_ok( 'Monitoring::GLPlugin' ) || print "Bail out!\n";
    use_ok( 'Monitoring::GLPlugin::SNMP' ) || print "Bail out!\n";
    use_ok( 'Monitoring::GLPlugin::UPNP' ) || print "Bail out!\n";
}

diag( "Testing Monitoring::GLPlugin $Monitoring::GLPlugin::VERSION, Perl $], $^X" );
