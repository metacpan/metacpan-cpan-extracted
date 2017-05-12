#!perl -T
use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'OpenServices::SNMP::Plugin::Updates' ) || print "Bail out!\n";
}

diag("Testing OpenServices::SNMP::Plugin::Updates $OpenServices::SNMP::Plugin::Updates::VERSION, $OpenServices::SNMP::Plugin::Updates::BASEOID, Perl $], $^X");
