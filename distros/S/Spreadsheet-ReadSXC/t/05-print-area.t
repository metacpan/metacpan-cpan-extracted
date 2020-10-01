use strict;
use Test::More tests => 8;
use File::Basename 'dirname';
use Spreadsheet::ParseODS;
use Data::Dumper;

my $d = dirname($0);

my $workbook = Spreadsheet::ParseODS->new()->parse("$d/print-area.ods");

my $areas = $workbook->get_print_areas;
is_deeply $areas, [[[1,1,4,1]],
                   undef,
                   [[0,0,0,0],[0,1,4,2],[6,2,8,5]]
                   ], "Retrieving all print areas works"
    or diag Dumper $areas;

my $area1 = $workbook->worksheet('printarea')->get_print_areas;
is_deeply $area1, [[1,1,4,1]], "Retrieving all print areas works"
    or diag Dumper $area1;
cell_content_ok( $workbook->worksheet('printarea'), $area1->[0], 'Should print');

my $area2 = $workbook->worksheet('no printarea')->get_print_areas;
is $area2, undef, "A sheet without a print area has undef"
    or diag Dumper $area2;

my $area3 = $workbook->worksheet('multiple printarea.C3')->get_print_areas;
is_deeply $area3, [[0,0,0,0],[0,1,4,2],[6,2,8,5]],
    "A sheet with multiple print areas has the expected results"
    or diag Dumper $area3;

cell_content_ok( $workbook->worksheet('multiple printarea.C3'), $area3->[0], 'printarea 1');
cell_content_ok( $workbook->worksheet('multiple printarea.C3'), $area3->[1], 'printarea2');
cell_content_ok( $workbook->worksheet('multiple printarea.C3'), $area3->[2], 'printarea3');


sub cell_content_ok {
    my( $sheet, $range, $value ) = @_;

    my $match;
    my $range_v = sprintf "[%s]", join ",", @$range;

    # Check the cell content for each print area
    for my $row ($range->[0]..$range->[2]) {
        for my $col ($range->[1]..$range->[3]) {
            my $v = $sheet->get_cell($row,$col)->value;
            if( $v ne $value ) {
                fail "The range $range_v has the value '$value'";
                diag "The first offending cell is at [$row,$col] with value $v";
                return;
            };
        };
    };
    pass "The range $range_v has the value '$value'";
}
