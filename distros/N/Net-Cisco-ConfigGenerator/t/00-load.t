#!perl -T
use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Net::Cisco::ConfigGenerator' ) || print "Bail out!\n";
}

diag( "Testing Net::Cisco::ConfigGenerator $Net::Cisco::ConfigGenerator::VERSION, Perl $], $^X" );
