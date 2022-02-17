#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'PINE64::PCF8574' ) || print "Bail out!\n";
}

diag( "Testing PINE64::PCF8574 $PINE64::PCF8574::VERSION, Perl $], $^X" );
