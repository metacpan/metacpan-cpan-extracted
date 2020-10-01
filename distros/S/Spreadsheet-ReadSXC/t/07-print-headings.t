use strict;
use Test::More tests => 9;
use File::Basename 'dirname';
use Spreadsheet::ParseODS;
use Data::Dumper;

my $d = dirname($0);

my $workbook = Spreadsheet::ParseODS->new()->parse("$d/print-titles.ods");
my $worksheet = $workbook->worksheet('Sheet1');

is $worksheet->col_max, 3, "We have four used columns"
    or diag Dumper $worksheet;

is $worksheet->row_max, 2, "We have three rows"
    or diag Dumper $worksheet;

my $cell = $worksheet->get_cell(0,2);
is $cell->value, "Heading1";

   $cell = $worksheet->get_cell(0,3);
is $cell->value, "Heading2";

for my $row (1..2) {
    for my $col (2..3) {
        my $cell = $worksheet->get_cell($row,$col);
        my $expected = sprintf "Content%d.%d", $row, $col-1;
        is $cell->value, $expected;
    };
};

is_deeply $worksheet->get_print_titles, {
    Column => [0,1],
    Row    => [0,0]
}, "Print headings";
