#!perl -T
use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'OpenServices::SNMP::Plugin::CVE' ) || print "Bail out!\n";
}

diag("Testing OpenServices::SNMP::Plugin::CVE $OpenServices::SNMP::Plugin::CVE::VERSION, $OpenServices::SNMP::Plugin::CVE::BASEOID, Perl $], $^X");
