use strict;
use Test::More;
use File::Basename 'dirname';
use Spreadsheet::ParseODS;
use Data::Dumper;

my $d = dirname($0);

my @cell_tests = (
    [0,0,"A1"],
    [0,1023,'AMJ1'],
);

plan tests => 0+@cell_tests;

for my $file (qw(wide.ods)) {
    my $workbook = Spreadsheet::ParseODS->new()->parse("$d/$file");

    my $sheet = $workbook->worksheet('Tabelle1');

    for my $t (@cell_tests) {
        my $c = $sheet->get_cell( $t->[0], $t->[1] );

        if( ! $c ) {
            diag Dumper $sheet->data;
        };

        my @r = Spreadsheet::ParseODS::sheetRef( $t->[2] );
        my $v = $sheet->get_cell( @r )->value;
        is $v, $t->[1]+1, "Cell at $t->[2] matches address @r";
    };
};
