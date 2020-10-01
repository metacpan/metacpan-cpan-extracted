use strict;
use Test::More;
use File::Basename 'dirname';
use Spreadsheet::ParseODS;
use Data::Dumper;

my $d = dirname($0);

plan tests => 2;

my $workbook = Spreadsheet::ParseODS->new()->parse("$d/merged.ods");

my $merged_areas = [$workbook->worksheets()]->[0]->merged_areas();
is_deeply $merged_areas, [
              [0,1,1,2], # B1:C2
              [1,0,2,0], # A2:A3
          ],
          "We read the proper merged areas"
    or diag Dumper $merged_areas;

my $workbook = Spreadsheet::ParseODS->new()->parse("$d/attr.ods");

my $max_col = $workbook->worksheet("Format")->col_max();
is $max_col, 2, "An (empty) merged column at the end still counts";
