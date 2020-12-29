use strict;
use Test::More;
use File::Basename 'dirname';
use Spreadsheet::ParseODS;

my $d = dirname($0);

plan tests => 2;

my $workbook;
my $ok = eval {
    $workbook = Spreadsheet::ParseODS->new(
        #readonly => 1,
    )->parse("$d/gh5-custom-styles.ods",
        readonly => 1
    );
    1;
};

is $ok, 1, "We don't crash when parsing the workbook"
    or diag $@;
note "<$_>" for map { $_->label } $workbook->worksheets;
my $name = $workbook->active_sheet_name;
is $name, "Tabelle", "We have an active sheet";
