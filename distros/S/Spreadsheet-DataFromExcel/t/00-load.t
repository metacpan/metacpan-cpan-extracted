use Test::More tests => 2;

BEGIN {
    use_ok('Spreadsheet::ParseExcel');
    use_ok( 'Spreadsheet::DataFromExcel' );
}

diag( "Testing Spreadsheet::DataFromExcel $Spreadsheet::DataFromExcel::VERSION, Perl $], $^X" );
