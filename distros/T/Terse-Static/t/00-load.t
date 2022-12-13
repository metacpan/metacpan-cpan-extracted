#!perl
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Terse::Static' ) || print "Bail out!\n";
}

diag( "Testing Terse::Static $Terse::Static::VERSION, Perl $], $^X" );
