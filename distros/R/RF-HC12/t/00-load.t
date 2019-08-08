#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'RF::HC12' ) || print "Bail out!\n";
}

diag( "Testing RF::HC12 $RF::HC12::VERSION, Perl $], $^X" );
