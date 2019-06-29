#!perl

use v5.10.1;
use strict;
use warnings FATAL => 'all';
use experimental qw(smartmatch);

use Test::More tests => 38;

use Sport::Analytics::NHL::Report;
use Sport::Analytics::NHL::Util qw(:file);

my $report;
my $game_path = 't/data/2011/0002/0010';
while (my ($type, $ext) = each %Sport::Analytics::NHL::Report::REPORT_TYPES) {
	my $file = "$game_path/$type.$ext";
	next unless -f $file;
	my $class = "Sport::Analytics::NHL::Report::$type";
	$report = Sport::Analytics::NHL::Report->new({ file => $file, type => $type });
	isa_ok($report, $class);
	if ($ext eq 'json') {
		isa_ok($report->{json}, 'HASH');
	}
	else {
		my $tree = $file;
		$tree =~ s/html/tree/;
		ok(-f $tree, 'tree stored');
		is($report->{source}, read_file($file), 'source stored');
		isa_ok($report->{html}, 'HTML::Element', 'html tree in object');
	}
	is($report->{type}, $type, 'type stored');
}
