#!perl
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Suricata::Monitoring' ) || print "Bail out!\n";
}

diag( "Testing Suricata::Monitoring $Suricata::Monitoring::VERSION, Perl $], $^X" );
