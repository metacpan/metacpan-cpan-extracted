#!perl -T
use strict;
use warnings FATAL => 'all';
use Test::More;
use Spreadsheet::CSV();
use IO::File();

plan tests => 1;

use CGI();
use Spreadsheet::CSV();

SKIP: {
	my $cgi = CGI->new();
	my $handle;
	eval {
		my $tmpfile = CGITempFile->new(1);
		my $tmp = $tmpfile->as_string;
		$handle = Fh->new('spreadsheet_csv',$tmp,0);
	} or do {
		require File::Temp;
		$handle = File::Temp::tempfile();
	};
	sysopen $handle, 't/data/sample.xlsx', Fcntl::O_RDONLY() or die "Failed to open 't/data/sample.xlsx' for reading:$!";
	binmode $handle;
	my @rows;
	my $csv = Spreadsheet::CSV->new();
	while (my $row = $csv->getline ($handle)) {
	    $row->[2] =~ m/Exclusive/ or next; # 3rd field should match
	    push @rows, $row;
	}   
	$csv->eof() or die $csv->error_diag();
	close $handle;
	ok(@rows == 2, "Successfully navigated the scenario in the POD using " . (ref $handle) . " as the input handle");
}

