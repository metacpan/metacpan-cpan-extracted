#!perl
use strict;
use Test::More tests => 1;
use File::Basename 'dirname';
use File::Temp 'tempfile';
use Spreadsheet::ReadSXC;
use Archive::Zip;

my $d = dirname($0);
my $sxc_file = "$d/t.sxc";

my $content = Archive::Zip->new($sxc_file)
                  ->memberNamed('content.xml')->contents;
my ($fh,$tempfile) = tempfile();
binmode $fh;
print $fh $content;
close $fh;

my $workbook_ref_from_xml = Spreadsheet::ReadSXC::read_xml_file($tempfile);
my $workbook_ref = Spreadsheet::ReadSXC::read_sxc($sxc_file);

is_deeply $workbook_ref_from_xml, $workbook_ref,
    "Reading from XML is the same as reading from a file";
