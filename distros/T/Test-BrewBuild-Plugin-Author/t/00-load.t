#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Test::BrewBuild::Plugin::Author' ) || print "Bail out!\n";
}

diag( "Testing Test::BrewBuild::Plugin::Author $Test::BrewBuild::Plugin::Author::VERSION, Perl $], $^X" );
