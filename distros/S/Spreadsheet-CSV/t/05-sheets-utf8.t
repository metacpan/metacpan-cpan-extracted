#!perl -T
use strict;
use warnings FATAL => 'all';
use Test::More;
use Spreadsheet::CSV();
use IO::File();
use Encode();

plan tests => 67;

MAIN: {
	my $encoded_string = "UTF-8 stuff is 'Ў'";
	my $decoded_string = $encoded_string;
	$decoded_string = Encode::decode('UTF-8', $decoded_string, 1);
	foreach my $file_name (qw(sample2.gnumeric sample2.ods sample2.sxc sample2.xls sample2.xlsx sample2.ksp)) {
		my $handle = IO::File->new('t/data/' . $file_name) or die "Screaming:$!";
		binmode $handle;
		my $spreadsheet = Spreadsheet::CSV->new();
		my $row = $spreadsheet->getline($handle);
		ok($row->[0] eq 'stuff on sheet 1', 'selected cell A1 on worksheet number 1 by default is "stuff on sheet 1" for $file_name');
		ok($spreadsheet->eof() eq '', "eof returned false");
		$row = $spreadsheet->getline($handle);
		ok((! defined $row) && ($spreadsheet->eof() == 1), "worksheet 1 only has 1 row for $file_name");
		$spreadsheet = Spreadsheet::CSV->new({ 'worksheet_number' => 1 });
		$row = $spreadsheet->getline($handle);
		ok($row->[0] eq 'stuff on sheet 1', 'selected cell A1 on selected worksheet number 1 is "stuff on sheet 1" for ' . $file_name);
		$spreadsheet = Spreadsheet::CSV->new({ 'worksheet_number' => 2 });
		$row = $spreadsheet->getline($handle);
		$row = $spreadsheet->getline($handle);
		ok($row->[0] eq $decoded_string, "selected cell A1 on selected worksheet number 2 is \"$encoded_string\" for $file_name");
		$spreadsheet = Spreadsheet::CSV->new({ 'worksheet_name' => 'First Sheet' });
		$row = $spreadsheet->getline($handle);
		ok($row->[0] eq 'stuff on sheet 1', 'selected cell A1 on selected worksheet name "First Sheet" is "stuff on sheet 1" for ' . $file_name);
		$spreadsheet = Spreadsheet::CSV->new({ 'worksheet_name' => 'Second Sheet' });
		$row = $spreadsheet->getline($handle);
		$row = $spreadsheet->getline($handle);
		ok($row->[0] eq $decoded_string, "selected cell A1 on selected worksheet name \"Second Sheet\" is \"$encoded_string\" for $file_name");
		$spreadsheet = Spreadsheet::CSV->new({ 'worksheet_name' => 'Third Sheet' });
		$row = $spreadsheet->getline($handle);
		ok((! defined $row) && ($spreadsheet->eof() eq ''), "worksheet name \"Third Sheet\" (it does not exist) correctly returns undef on getline with eof set to '' $file_name");
		ok($spreadsheet->error_diag() eq 'ENOENT - Worksheet Third Sheet not found', "error_diag() is correctly set to 'ENOENT - Worksheet Third Sheet not found':" . $spreadsheet->error_diag());
		$spreadsheet = Spreadsheet::CSV->new({ 'worksheet_number' => 43 });
		$row = $spreadsheet->getline($handle);
		ok((! defined $row) && ($spreadsheet->eof() eq ''), "worksheet number 43 (it does not exist) correctly returns undef on getline with eof set to '' $file_name");
		ok($spreadsheet->error_diag() eq 'ENOENT - Worksheet 43 not found', "error_diag() is correctly set to 'ENOENT - Worksheet 43 not found':" . $spreadsheet->error_diag());
	}
	foreach my $file_name (qw(sample2.csv)) {
		my $handle = IO::File->new('t/data/' . $file_name) or die "Screaming:$!";
		binmode $handle;
		my $spreadsheet = Spreadsheet::CSV->new({ 'worksheet_name' => 'Second Sheet' });
		my $row = $spreadsheet->getline($handle);
		$row = $spreadsheet->getline($handle);
		ok($row->[0] eq $decoded_string, "selected cell A1 on selected worksheet name \"Second Sheet\" is \"$encoded_string\" for $file_name");
	}
}

1;

