#!perl
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Tesla::Vehicle' ) || print "Bail out!\n";
}

diag( "Testing Tesla::Vehicle $Tesla::Vehicle::VERSION, Perl $], $^X" );
