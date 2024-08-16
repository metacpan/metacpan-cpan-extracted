use strict;
use Test::More;
use File::Basename 'dirname';
use Spreadsheet::ParseODS;
use Data::Dumper;

my $d = dirname($0);

my %tests = (
    "$d/print-area.ods" => 'multiple printarea.C3',
    "$d/Dates.ods" => 'DateTest',
    "$d/hidden-cols.ods" => 'vhhhvh',
);

plan tests => 2 * scalar keys %tests;

for my $test (sort keys %tests) {
    my $name = $tests{ $test };

    my $workbook = Spreadsheet::ParseODS->new()->parse($test);

    is $workbook->_settings->active_sheet_name, $name, "$test active sheet is $name";
    isnt $workbook->get_active_sheet, undef, "We find a sheet named '$name'";
}
