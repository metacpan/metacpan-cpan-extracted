use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::NoTabs 0.08

use Test::More 0.88;
use Test::NoTabs;

my @files = (
    'bin/spreadsheet_to_template',
    'bin/template_to_spreadsheet',
    'lib/Spreadsheet/Template.pm',
    'lib/Spreadsheet/Template/Generator.pm',
    'lib/Spreadsheet/Template/Generator/Parser.pm',
    'lib/Spreadsheet/Template/Generator/Parser/Excel.pm',
    'lib/Spreadsheet/Template/Generator/Parser/XLSX.pm',
    'lib/Spreadsheet/Template/Helpers/Xslate.pm',
    'lib/Spreadsheet/Template/Processor.pm',
    'lib/Spreadsheet/Template/Processor/Identity.pm',
    'lib/Spreadsheet/Template/Processor/Xslate.pm',
    'lib/Spreadsheet/Template/Writer.pm',
    'lib/Spreadsheet/Template/Writer/Excel.pm',
    'lib/Spreadsheet/Template/Writer/XLSX.pm',
    't/00-compile.t',
    't/basic.t',
    't/cell-to-row-col.t',
    't/data/Test.json',
    't/data/merge.json',
    't/data/template.json',
    't/data/utf8.json',
    't/merge.t',
    't/template.t',
    't/utf8.t'
);

notabs_ok($_) foreach @files;
done_testing;
