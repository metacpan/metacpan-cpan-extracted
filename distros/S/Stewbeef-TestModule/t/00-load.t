#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Stewbeef::TestModule' ) || print "Bail out!\n";
}

diag( "Testing Stewbeef::TestModule $Stewbeef::TestModule::VERSION, Perl $], $^X" );
