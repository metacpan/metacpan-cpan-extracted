use strict;
use Test::More tests => 10;
use File::Basename 'dirname';
use Spreadsheet::ReadSXC;
use Archive::Zip;
use Data::Dumper;

my $d = dirname($0);

my $zip = Archive::Zip->new();
ok(( $zip->read("$d/t.sxc") == 0 ), 'Unzipping .sxc file');

my $workbook_ref = Spreadsheet::ReadSXC::read_sxc("$d/t.sxc");

my @sheets = sort keys %$workbook_ref;

ok((($sheets[0] eq "Sheet1") and ($sheets[1] eq "Sheet2") and ($sheets[2] eq "Sheet3")), 'Comparing spreadsheet names');

my @sheet1_data = (['-$1,500.99', '17', undef],[undef, undef, undef],['one', 'more', 'cell']);
my @sheet1_curr = ([-1500.99, 17, undef],[undef, undef, undef],['one', 'more', 'cell']);
my @sheet1_data_ods = (['-$1,500.99', '17', undef],[undef, undef, undef],['one', 'more', 'cell'],[undef,undef,undef],['Date','1980-11-21', undef]);
my @sheet1_curr_date_multiline = (
    [-1500.99, 17, undef],
    [undef, undef, undef],
    ['one', 'more', 'cell'],
    [undef,undef,undef],
    ['Date','1980-11-21', undef],
    ["A cell value\nThat contains\nMultiple lines",undef,undef],
    ["\nA cell that starts\nWith an empty line\nAnd ends with an empty\nLine as well\n",undef,undef],
);
my @sheet1_curr_date = ([-1500.99, 17, undef],[undef, undef, undef],['one', 'more', 'cell'],[undef,undef,undef],['Date','1980-11-21', undef]);
my @sheet3_data = (['Both alike', 'Both alike', undef], [undef, undef, undef], [undef, undef, undef], [undef, undef, undef], [undef, undef, undef], [undef, undef, undef], [undef, undef, undef], [undef, undef, undef], [undef, undef, undef], [undef, undef, undef], [undef, undef, undef], [undef, undef, undef], [undef, undef, undef], [undef, undef, 'Cell C14']);

my @sheet1 = @{$$workbook_ref{"Sheet1"}};
is_deeply \@sheet1, \@sheet1_data, 'Verifying Sheet1'
    or diag Dumper \@sheet1;

is_deeply $workbook_ref->{"Sheet2"}, [], 'Verifying Sheet2';

my @sheet3 = @{$$workbook_ref{"Sheet3"}};
is_deeply \@sheet3, \@sheet3_data, 'Verifying Sheet3';

ok Spreadsheet::ReadSXC::read_sxc("$d/t.sxc"),
  "We can read a file twice";

$workbook_ref = Spreadsheet::ReadSXC::read_sxc("$d/t.sxc", { StandardCurrency => 1 });
@sheet1 = @{$$workbook_ref{"Sheet1"}};
is_deeply \@sheet1, \@sheet1_curr, 'Verifying Sheet1 (raw)';

$workbook_ref = Spreadsheet::ReadSXC::read_sxc("$d/t-date.ods", { StandardDate => 1 });
@sheet1 = @{$$workbook_ref{"Sheet1"}};
is_deeply \@sheet1, \@sheet1_data_ods, 'Verifying Sheet1 (raw, ods)';

$workbook_ref = Spreadsheet::ReadSXC::read_sxc("$d/t-date.ods", { StandardCurrency => 1, StandardDate => 1 });
@sheet1 = @{$$workbook_ref{"Sheet1"}};
is_deeply \@sheet1, \@sheet1_curr_date, 'Verifying Sheet1 (raw, ods)';

$workbook_ref = Spreadsheet::ReadSXC::read_sxc("$d/t-multiline.ods",
    { StandardCurrency => 1, StandardDate => 1, ReplaceNewlineWith => "\n" });
@sheet1 = @{$$workbook_ref{"Sheet1"}};
$Data::Dumper::Useqq = 1;
is_deeply \@sheet1, \@sheet1_curr_date_multiline, 'Verifying Sheet1 (raw, ods multiline)'
    or do { diag Dumper \@sheet1 };
