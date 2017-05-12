#!perl -T
use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Statistics::Reproducibility' ) || print "Bail out!\n";
}

diag( "Testing Statistics::Reproducibility $Statistics::Reproducibility::VERSION, Perl $], $^X" );
