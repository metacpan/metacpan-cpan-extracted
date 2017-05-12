#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Spreadsheet::ExcelHashTable' ) || print "Bail out!\n";
}

diag( "Testing Spreadsheet::ExcelHashTable $Spreadsheet::ExcelHashTable::VERSION, Perl $], $^X" );
