use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::EOLTests 0.18

use Test::More 0.88;
use Test::EOL;

my @files = (
    'lib/Spreadsheet/ParseXLSX.pm',
    'lib/Spreadsheet/ParseXLSX/Decryptor.pm',
    'lib/Spreadsheet/ParseXLSX/Decryptor/Agile.pm',
    'lib/Spreadsheet/ParseXLSX/Decryptor/Standard.pm',
    't/00-compile.t',
    't/basic.t',
    't/bug-10.t',
    't/bug-11.t',
    't/bug-12.t',
    't/bug-13.t',
    't/bug-14.t',
    't/bug-15.t',
    't/bug-16.t',
    't/bug-17.t',
    't/bug-2.t',
    't/bug-29.t',
    't/bug-3.t',
    't/bug-32.t',
    't/bug-38.t',
    't/bug-4.t',
    't/bug-41.t',
    't/bug-5.t',
    't/bug-57.t',
    't/bug-6-2.t',
    't/bug-6.t',
    't/bug-61.t',
    't/bug-7.t',
    't/bug-8.t',
    't/cell-to-row-col.t',
    't/column-formats.t',
    't/encryption.t',
    't/hidden-row-and-column.t',
    't/hidden-sheet.t',
    't/page-Setup.t',
    't/rich.t',
    't/tab-color.t',
    't/target-abspath.t'
);

eol_unix_ok($_, { trailing_whitespace => 1 }) foreach @files;
done_testing;
