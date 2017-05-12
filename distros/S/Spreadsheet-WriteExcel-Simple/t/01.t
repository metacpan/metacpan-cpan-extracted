#!/usr/bin/perl -w

use strict;
use Spreadsheet::WriteExcel::Simple;
use Test::More;

eval {
	require File::Temp;
	require Spreadsheet::ParseExcel;
};

if ($@) {
	plan skip_all => 'Need File::Temp and Spreadsheet::ParseExcel to test';
}

plan tests => 14;

File::Temp->import(qw/tempfile tempdir/);
my $dir1 = tempdir(CLEANUP => 1);
for (1 .. 2) {
	my ($fh1, $name1) = tempfile(DIR => $dir1);

	# Write our our test file.
	my $ss = Spreadsheet::WriteExcel::Simple->new;
	$ss->write_bold_row([qw/foo bar baz/]);
	$ss->write_row([qw/1 fred 2001-01-01/]);
	$ss->save($name1);

	# Now read it back in
	my $oExcel = new Spreadsheet::ParseExcel;
	ok my $oBook = $oExcel->Parse($name1), "Parse $name1\n";
	my $oWkS = $oBook->{Worksheet}[0];

	is($oWkS->{Cells}[0][0]->Value, 'foo', 'heading: foo');
	is($oWkS->{Cells}[0][1]->Value, 'bar', 'heading: bar');
	is($oWkS->{Cells}[0][2]->Value, 'baz', 'heading: baz');

	is($oWkS->{Cells}[1][0]->Value, '1',          'data: 1');
	is($oWkS->{Cells}[1][1]->Value, 'fred',       'data: fred');
	is($oWkS->{Cells}[1][2]->Value, '2001-01-01', 'data: date');
}
