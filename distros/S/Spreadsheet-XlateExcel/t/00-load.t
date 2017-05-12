#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Spreadsheet::XlateExcel' ) || print "Bail out!
";
}

diag( "Testing Spreadsheet::XlateExcel $Spreadsheet::XlateExcel::VERSION, Perl $], $^X" );
