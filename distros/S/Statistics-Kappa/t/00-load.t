#!perl
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Statistics::Kappa::Cohen' ) || print "Bail out!\n";
}

diag( "Testing Statistics::Kappa::Cohen $Statistics::Kappa::Cohen::VERSION, Perl $], $^X" );
