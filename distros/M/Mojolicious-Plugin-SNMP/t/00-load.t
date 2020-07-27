#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Mojolicious::Plugin::SNMP' ) || print "Bail out!\n";
}

diag( "Testing Mojolicious::Plugin::SNMP $Mojolicious::Plugin::SNMP::VERSION, Perl $], $^X" );
