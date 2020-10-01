use strict;
use Test::More tests => 1;
use File::Basename 'dirname';
use Spreadsheet::ParseODS;
use Data::Dumper;

my $d = dirname($0);

my $workbook = Spreadsheet::ParseODS->new()->parse("$d/hidden-sheet.ods");

my %sheets = map { $_->label => $_->is_sheet_hidden } $workbook->worksheets;
is_deeply \%sheets, {
    Sheet1 => undef,
    "hidden sheet" => 1,
    Sheet3 => undef
}, "Hidden sheets get marked as such "
or diag Dumper \%sheets;

