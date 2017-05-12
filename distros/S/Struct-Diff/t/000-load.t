#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More tests => 1;

BEGIN {
    use_ok( 'Struct::Diff' ) || print "Bail out!\n";
}

diag( "Testing Struct::Diff $Struct::Diff::VERSION, Perl $], $^X" );
