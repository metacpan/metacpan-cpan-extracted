#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Table::Hack' ) || print "Bail out!\n";
}

diag( "Testing Table::Hack $Table::Hack::VERSION, Perl $], $^X" );
