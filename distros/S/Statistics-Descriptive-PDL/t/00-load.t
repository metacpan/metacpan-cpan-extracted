#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Statistics::Descriptive::PDL' ) || print "Bail out!\n";
}

diag( "Testing Statistics::Descriptive::PDL $Statistics::Descriptive::PDL::VERSION, Perl $], $^X" );
