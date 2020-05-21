#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'PINE64::MAX7219' ) || print "Bail out!\n";
}

diag( "Testing PINE64::MAX7219 $PINE64::MAX7219::VERSION, Perl $], $^X" );
