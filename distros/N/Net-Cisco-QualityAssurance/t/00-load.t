#!perl -T
use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Net::Cisco::QualityAssurance' ) || print "Bail out!\n";
}

diag( "Testing Net::Cisco::QualityAssurance $Net::Cisco::QualityAssurance::VERSION, Perl $], $^X" );
