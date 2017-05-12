#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Spreadsheet::WriteExcel::Styler' ) || print "Bail out!
";
}

diag( "Testing Spreadsheet::WriteExcel::Styler $Spreadsheet::WriteExcel::Styler::VERSION, Perl $], $^X" );
