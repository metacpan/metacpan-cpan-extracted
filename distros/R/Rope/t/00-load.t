#!perl
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Rope' ) || print "Bail out!\n";
}

diag( "Testing Rope $Rope::VERSION, Perl $], $^X" );
