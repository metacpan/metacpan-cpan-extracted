#!/usr/bin/perl

use Test::More tests => 1;

BEGIN {
    use_ok( 'Query::Abstract' ) || print "Bail out!\n";
}

diag( "Testing Query::Abstract $Query::Abstract::VERSION, Perl $], $^X" );
