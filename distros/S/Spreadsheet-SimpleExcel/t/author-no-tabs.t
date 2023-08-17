
BEGIN {
  unless ($ENV{AUTHOR_TESTING}) {
    print qq{1..0 # SKIP these tests are for testing by the author\n};
    exit
  }
}

use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::NoTabs 0.15

use Test::More 0.88;
use Test::NoTabs;

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

notabs_ok($_) foreach @files;
done_testing;
