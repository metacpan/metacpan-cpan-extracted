use strict;
use Test::More tests => 6;
use File::Basename 'dirname';
use Spreadsheet::ParseODS;
use Data::Dumper;

my $d = dirname($0);

my $workbook = Spreadsheet::ParseODS->new()->parse("$d/hyperlink.ods");
my $worksheet = $workbook->worksheet('Sheet1');

is $worksheet->col_max, 0, "We have one used column"
    or diag Dumper $worksheet;

my $cell = $worksheet->get_cell(0,0);
is $cell->value, "A cell";

my $cell = $worksheet->get_cell(1,0);
is $cell->value, "A hyperlink to example.com";
is $cell->get_hyperlink, 'https://example.com/',
    "Retrieving the hyperlink works";

my $cell = $worksheet->get_cell(2,0);
is $cell->value, "A mailto hyperlink";
is $cell->get_hyperlink, 'mailto:corion@example.com?subject=Example mail hyperlink subject',
    "Retrieving the hyperlink works";
