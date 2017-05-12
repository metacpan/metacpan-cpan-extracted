#!perl -T
use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Statistics::ANOVA::KW' ) || print "Bail out!\n";
}

diag( "Testing Statistics::ANOVA::KW $Statistics::ANOVA::KW::VERSION, Perl $], $^X" );

1;
