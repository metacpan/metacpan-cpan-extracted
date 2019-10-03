#!perl
use strict;
use Test::More tests => 1;
use File::Basename 'dirname';
use Spreadsheet::ReadSXC;

my $d = dirname($0);
my $sxc_file = "$d/t.sxc";


open my $fh, '<', $sxc_file
    or die "Couldn't read '$sxc_file': $!";
binmode $fh;
my $workbook_ref_from_fh = Spreadsheet::ReadSXC::read_sxc_fh($fh);
my $workbook_ref = Spreadsheet::ReadSXC::read_sxc($sxc_file);

is_deeply $workbook_ref_from_fh, $workbook_ref,
    "Reading from FH is the same as reading from a file";
