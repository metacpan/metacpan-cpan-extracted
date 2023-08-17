
BEGIN {
  unless ($ENV{AUTHOR_TESTING}) {
    print qq{1..0 # SKIP these tests are for testing by the author\n};
    exit
  }
}

use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::NoBOM 0.002

use Test::More 0.88;
use Test::BOM;

my @files = (
    'lib/Spreadsheet/SimpleExcel.pm',
    't/01_basic.t',
    't/02_synopsis.t',
    't/03_big.t',
    't/04_file.t',
    't/05_long_sheetname.t',
    't/06_warnings_worksheet.t',
    't/07_warnings_row.t',
    't/08_warnings_header.t',
    't/09_xlsx.t'
);

ok(file_hasnt_bom($_)) for @files;

done_testing;
