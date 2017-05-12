#!perl -T
use strict;
use warnings FATAL => 'all';
use Test::More;
use Spreadsheet::CSV();
use IO::File();

plan tests => 30;

foreach my $file_name (qw(missing_worksheet.xlsx missing_content.ods missing_mimetype.ods unknown_mimetype.ods bad_archive.xlsx bad_gzip.gnumeric missing_maindoc.ksp corrupt_maindoc.ksp cpan_banner.csv bad_definition.csv)) {
	my $handle = IO::File->new('t/data/corrupt/' . $file_name) or die "Screaming:$!";
	binmode $handle;
	my $spreadsheet = Spreadsheet::CSV->new();
	my $result = $spreadsheet->getline($handle);
	ok(not(defined $result), "getline returned not defined on corrupt content");
	ok($spreadsheet->eof() eq '', "eof returned false");
	ok($spreadsheet->error_diag() =~ /^(XML|ZIP|GZIP|CSV)\ \-\ /, "Correctly detects corruption in spreadsheet '$file_name':" . $spreadsheet->error_diag());
}

1;

