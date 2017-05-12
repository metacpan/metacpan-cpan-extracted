#!/usr/bin/perl -w

use strict;
use Test::More;
use Data::Dumper;

BEGIN {
  eval "require DBD::SQLite; use Spreadsheet::ParseExcel::Simple";
  plan $@ ? (skip_all => 'needs DBD::SQLite + Spreadsheet::ParseExcel::Simple for testing') 
		: (tests => 5);
}

use_ok 'Spreadsheet::WriteExcel::FromDB';

BEGIN { unlink 'test.db'; }
my $dbh = DBI->connect("dbi:SQLite:dbname=test.db", "", "");

#--------------------------------------------------------------------
# Setup
#--------------------------------------------------------------------

$dbh->do(
	qq{
  CREATE TABLE company (
    id   INTEGER NOT NULL PRIMARY KEY,
    ref  INTEGER,
    name VARCHAR(255)
  )
}
);

$dbh->do('INSERT INTO company (ref, name) VALUES (1031, "Amazon")');
$dbh->do('INSERT INTO company (ref, name) VALUES (1501, "eBay")');
$dbh->do('INSERT INTO company (ref, name) VALUES (1938, "Google")');

#--------------------------------------------------------------------
# Simple
#--------------------------------------------------------------------

{
	my $SS = 'test.xls';
	my $ss = Spreadsheet::WriteExcel::FromDB->read($dbh, 'company');
	$ss->write_xls($SS);
	my $xls = Spreadsheet::ParseExcel::Simple->read($SS);
	is $xls->sheets, 1, "One sheet spreadsheet";
	my $sheet = ($xls->sheets)[0];
	my @data = map [ $sheet->next_row ], 1 .. 4;
	is_deeply \@data,
		[
		[ 'id', 'ref',  'name' ],
		[ '1',  '1031', 'Amazon' ],
		[ '2',  '1501', 'eBay' ],
		[ '3',  '1938', 'Google' ]
		],
		"Correct spreadsheet";
}

#--------------------------------------------------------------------
# Ignore Columns
#--------------------------------------------------------------------

{
	my $SS = 'test2.xls';
	my $ss = Spreadsheet::WriteExcel::FromDB->read($dbh, 'company');
	$ss->ignore_columns(qw/id ref/);
	$ss->write_xls($SS);
	my $xls = Spreadsheet::ParseExcel::Simple->read($SS);
	my $sheet = ($xls->sheets)[0];
	my @data = map [ $sheet->next_row ], 1 .. 4;
	is_deeply \@data,
		[ [ 'name' ], [ 'Amazon' ], [ 'eBay' ], [ 'Google' ] ],
		"Correct spreadsheet" or diag Dumper \@data;
}

#--------------------------------------------------------------------
# Restrictions
#--------------------------------------------------------------------

{
	my $SS = 'test3.xls';
	my $ss = Spreadsheet::WriteExcel::FromDB->read($dbh, 'company');
	$ss->ignore_columns(qw/id ref/);
	$ss->restrict_rows('id > 1');
	$ss->write_xls($SS);
	my $xls = Spreadsheet::ParseExcel::Simple->read($SS);
	my $sheet = ($xls->sheets)[0];
	my @data = map [ $sheet->next_row ], 1 .. 3;
	is_deeply \@data,
		[ [  'name' ], , [ 'eBay' ], [ 'Google' ] ],
		"Correct spreadsheet" or diag Dumper \@data;
}

