#!perl -T
use strict;
use warnings FATAL => 'all';
use Test::More;
use Spreadsheet::CSV();
use IO::File();

plan tests => 21;

foreach my $file_name (qw(shared_strings.xlsx workbook.xlsx worksheet.xlsx content.ods content.sxc sample.gnumeric maindoc.ksp)) {
	my $handle = IO::File->new('t/data/bombs/' . $file_name) or die "Screaming:$!";
	binmode $handle;
	my $spreadsheet = Spreadsheet::CSV->new();
	my $result = $spreadsheet->getline($handle);
	ok(not(defined $result), "getline returned not defined on an XML bomb");
	ok($spreadsheet->eof() eq '', "eof returned false");
	ok($spreadsheet->error_diag() =~ /^XML - Invalid XML in [\w\/. ]+:XML Entities have been detected and rejected in the XML, due to security concerns/, "Correctly detects XML bomb in $file_name:" . $spreadsheet->error_diag());
}

1;

