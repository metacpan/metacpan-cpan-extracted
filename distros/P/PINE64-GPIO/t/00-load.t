#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'PINE64::GPIO' ) || print "Bail out!\n";
}

diag( "Testing PINE64::GPIO $PINE64::GPIO::VERSION, Perl $], $^X" );
