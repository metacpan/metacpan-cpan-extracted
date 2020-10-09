use strict;
use Test::More;
use File::Basename 'dirname';
use Spreadsheet::ParseODS;

my $d = dirname($0);

plan tests => 1;

my $workbook;
my $ok = eval {
    $workbook = Spreadsheet::ParseODS->new(
        #readonly => 1,
    )->parse("$d/GasLichtWater.ods",
        readonly => 1
    );
    1;
};

is $ok, 1, "We don't crash when parsing the workbook"
    or diag $@;
