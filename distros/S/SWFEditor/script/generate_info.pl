#!/usr/bin/env perl
use strict;
use warnings;
use Config::Pit;
use Net::Google::Spreadsheets;
use Text::UnicodeTable::Simple;
use FindBin;
use utf8;

my $service = Net::Google::Spreadsheets->new(pit_get('google.com'));
my $sheet = $service->spreadsheet(
	{ key => '0Av_yCMlVZigWdC1xU1VLekFGUWtMUTM0V05XV3FjQWc', }
);
my $worksheet = $sheet->worksheet(
	{ title => 'sheet', }
);

my $t = Text::UnicodeTable::Simple->new;
$t->set_header('pm', 'xs', 't', 't2');

my @rows = $worksheet->rows;
my $i = 0;
for my $row (@rows) {
	my $c = $row->content;
	if (defined $c->{pm} && $c->{pm} =~ /^\[.+?\]$/) {
		$t->add_row_line() if ($i++);
		$t->add_row($c->{pm});
		$t->add_row_line();
	} else {
		$t->add_row($c->{pm} || '', $c->{xs} || '', $c->{t} || '', $c->{t2} || '');
	}
}
$t->add_row_line();

my $TESTINFO = $FindBin::Bin.'/../TESTINFO';
open my $fh, '>', $TESTINFO;
print $fh $t->draw;
close $fh;
