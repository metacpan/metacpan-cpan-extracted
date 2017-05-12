#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Test::BrewBuild::Plugin::TestAgainst' ) || print "Bail out!\n";
}

diag( "Testing Test::BrewBuild::Plugin::TestAgainst $Test::BrewBuild::Plugin::TestAgainst::VERSION, Perl $], $^X" );
