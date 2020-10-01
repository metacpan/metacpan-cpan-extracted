use strict;
use Test::More;
use File::Basename 'dirname';
use Spreadsheet::ParseODS;

my $d = dirname($0);

plan tests => 3;

my $workbook;
my $ok = eval {
    $workbook = Spreadsheet::ParseODS->new(
        #readonly => 1,
    )->parse("$d/test_spreadsheet_import.ods",
        readonly => 1
    );
    1;
};

is $ok, 1, "We don't crash when parsing the workbook"
    or diag $@;
note "<$_>" for map { $_->label } $workbook->worksheets;
my $name = $workbook->active_sheet_name;
is $name, undef, "We have no active sheet name";

my $active_sheet = $workbook->get_active_sheet;
# we should see no warning

is $active_sheet, undef, "We have no active sheet";
