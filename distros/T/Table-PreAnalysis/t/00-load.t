#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Table::PreAnalysis' ) || print "Bail out!\n";
}

diag( "Testing Table::PreAnalysis $Table::PreAnalysis::VERSION, Perl $], $^X" );
