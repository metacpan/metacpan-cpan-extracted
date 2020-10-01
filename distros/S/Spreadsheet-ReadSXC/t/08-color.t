use strict;
use Test::More tests => 14;
use File::Basename 'dirname';
use Spreadsheet::ParseODS;
use Data::Dumper;

my $d = dirname($0);

my @cell_tests = (
    [0,2,"ce8"],
    [2,0,"ce4"],
    [3,0,"ce5"],
    [4,0,"ce6"],
    [5,0,"ce11"],
    [5,2,"ce14"],
);

for my $file (qw(colors.ods colors.fods)) {
    my $workbook = Spreadsheet::ParseODS->new()->parse("$d/$file");

    my $sheet = $workbook->worksheet('Red tab');
    is $sheet->get_tab_color, '#ff0000';

    for my $t (@cell_tests) {
        my $c = $sheet->get_cell( $t->[0], $t->[1] );

        if( ! $c ) {
            diag Dumper $sheet->data->[4];
        };

        my $value = $c->value;
        my $name = "Style of ($t->[0], $t->[1]) is $t->[2] ($value)";

        is $c->style, $t->[2], $name;
    };
};
