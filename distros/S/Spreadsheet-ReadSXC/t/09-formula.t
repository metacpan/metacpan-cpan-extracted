use strict;
use Test::More;
use File::Basename 'dirname';
use Spreadsheet::ParseODS;
use Data::Dumper;

my $d = dirname($0);

my @cell_tests = (
    [0,2,"=2+2"],
    [1,2,'=SUM([.E$1:.E$1048576])'],
);

plan tests => 0+@cell_tests;

for my $file (qw(formula.ods)) {
    my $workbook = Spreadsheet::ParseODS->new()->parse("$d/$file");

    my $sheet = $workbook->worksheet('Tabelle1');

    for my $t (@cell_tests) {
        my $c = $sheet->get_cell( $t->[0], $t->[1] );

        if( ! $c ) {
            diag Dumper $sheet->data;
        };

        my $name = $sheet->get_cell($t->[0], 0)->value;
        my $literal = $sheet->get_cell($t->[0], 1)->value;
        my $formula = $c->formula;
        my $visual = "$name ($literal)";

        is $formula, $t->[2], $visual;
    };
};
