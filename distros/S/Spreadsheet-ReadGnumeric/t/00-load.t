#!perl
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Spreadsheet::ReadGnumeric' ) || print "Bail out!\n";
}

diag( "Testing Spreadsheet::ReadGnumeric $Spreadsheet::ReadGnumeric::VERSION, Perl $], $^X" );
