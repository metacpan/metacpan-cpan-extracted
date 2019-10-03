#!perl
use strict;
use Test::More tests => 3;
use File::Basename 'dirname';
use Spreadsheet::ReadSXC;
use Data::Dumper;

my $d = dirname($0);
my $xml_file = "$d/text-outside-cell.xml";

my $sheet;
my $ok = eval {
    $sheet = Spreadsheet::ReadSXC::read_xml_file($xml_file);
    1;
};
my $err = $@;
is $ok, 1, "We can parse this XML";
is $@, '', "No error was raised";

is_deeply $sheet, {
    "Sheet1" => [
        ['A1','B1',undef,'D1'],
        ['A2','B2',undef,undef],
        ['A3',undef,'C3','D3'],
        ['A4','B4','C4',undef],
    ],
    "Second Sheet" => [
        ['x',undef,'x',undef,'x'],
        [undef,'x',undef,'x',undef],
        ['x',undef,'x',undef,'x'],
    ],
}, "The sheet looks as we want it"
or diag Dumper $sheet;
