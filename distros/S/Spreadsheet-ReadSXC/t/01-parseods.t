use strict;
use Test::More tests => 2;
use File::Basename 'dirname';
use Spreadsheet::ParseODS;
use Data::Dumper;

my $d = dirname($0);

my $workbook = Spreadsheet::ParseODS->new()->parse("$d/t.sxc");

my @s = $workbook->worksheets;

my @sheets = map { $_->label } $workbook->worksheets;

is_deeply \@sheets, [qw[
    Sheet1 Sheet2 Sheet3
]], "Correct spreadsheet names"
or diag Dumper \@sheets;

my @sheet1_raw = (['-$1,500.99', '17', undef],[undef, undef, undef],['one', 'more', 'cell']);
my @sheet1_curr = ([-1500.99, 17, undef],[undef, undef, undef],['one', 'more', 'cell']);

my $sheet1 = $workbook->worksheet('Sheet1');

my @raw_data;
my ($minrow,$maxrow) = $sheet1->row_range;
for my $row ($minrow..$maxrow) {
    $raw_data[ $row ] = [];
    my ($mincol,$maxcol) = $sheet1->col_range;
    for my $col ($mincol..$maxcol) {
        $raw_data[ $row ]->[ $col ] = $sheet1->get_cell($row,$col)->value;
    };
};
is_deeply \@raw_data, \@sheet1_raw, "Raw cell values"
    or diag Dumper \@raw_data;

my @sheet1_curr_date_multiline = (
    [-1500.99, 17, undef],
    [undef, undef, undef],
    ['one', 'more', 'cell'],
    [undef,undef,undef],
    ['Date','1980-11-21', undef],
    ["A cell value\nThat contains\nMultiple lines",undef,undef],
    ["\nA cell that starts\nWith an empty line\nAnd ends with an empty\nLine as well\n",undef,undef],
);
