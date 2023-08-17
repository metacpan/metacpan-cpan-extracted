#!perl
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Terse::View::TT' ) || print "Bail out!\n";
}

diag( "Testing Terse::View::TT $Terse::View::TT::VERSION, Perl $], $^X" );
