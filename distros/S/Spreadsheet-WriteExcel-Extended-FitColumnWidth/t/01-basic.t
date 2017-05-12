#!perl -T

use strict;
use warnings;
use Test::More tests => 2;

require_ok('Spreadsheet::WriteExcel::Extended::FitColumnWidth');

my @headings = qw{ Fruit Colour Price/Kg };
my $workbook = Spreadsheet::WriteExcel::Extended::FitColumnWidth->new({
       filename => 'test.xls',
       sheets   => [ { name => 'Test Data', headings => \@headings}, ],
       });
       
unless ($workbook)
{
	diag("Failed to create workbook from call to new");
}
my $worksheet = $workbook->{__extended_sheets__}[0];
$worksheet->write_row(1, 0, [ 'Apple - Pink Lady',    'Shiny Red',   '3.25' ], $workbook->get_format('red'));
$worksheet->write_row(2, 0, [ 'Apple - Granny Smith', 'Green', '2.95' ], $workbook->{__extended_format_green__});
$worksheet->write_row(3, 0, [ 'Original Carrot', 'Purple', '5.95' ], $workbook->{__extended_format_purple_bold__});
$worksheet->write_row(4, 0, [ 'Orange', 'Orange', '6.15' ], $workbook->{__extended_format_orange_bg__});
$workbook->close();


pass("Created a basic spreadsheet") if (-f 'test.xls');

