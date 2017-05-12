use Test::More tests => 3;

BEGIN {
    use_ok('Class::Data::Accessor');
    use_ok('Spreadsheet::WriteExcel');
	use_ok( 'Spreadsheet::DataToExcel' );
}

diag( "Testing Spreadsheet::DataToExcel $Spreadsheet::DataToExcel::VERSION, Perl $], $^X" );
