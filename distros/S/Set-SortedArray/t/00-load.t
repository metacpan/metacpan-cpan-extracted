#!perl

use Test::More tests => 1;

BEGIN {
    use_ok( 'Set::SortedArray' ) || print "Bail out!\n";
}

diag( "Testing Set::SortedArray $Set::SortedArray::VERSION, Perl $], $^X" );
