use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Statistics::ANOVA::Friedman' ) || print "Bail out!\n";
}

diag( "Testing Statistics::ANOVA::Friedman $Statistics::ANOVA::Friedman::VERSION, Perl $], $^X" );

1;
