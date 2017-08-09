#!perl -T
use strict;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'My::FileDIff' ) || print "Bail out!\n";
}

diag( "Testing My::FileDIff $My::FileDIff::VERSION, Perl $], $^X" );
