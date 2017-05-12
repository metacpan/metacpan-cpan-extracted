#!/usr/bin/env perl

use Test::More tests => 1;

BEGIN {
    use_ok( 'Set::Functional' ) || print "Bail out!\n";
}

diag( "Testing Set::Functional $Set::Functional::VERSION, Perl $], $^X" );
