#!perl

use v5.10.1;
use strict;
use warnings FATAL => 'all';
use experimental qw(smartmatch);

use Test::More tests => 6;

use Sport::Analytics::NHL::Report::Player;
use Sport::Analytics::NHL::Util qw(:file);

my $report;
for (8448208,8448321,8470794) {
	$report = Sport::Analytics::NHL::Report::Player->new(
		read_file("t/data/players/$_.json"),
	);
	isa_ok($report, 'Sport::Analytics::NHL::Report::Player');
	is($report->{json}{id}, $_, "JSON stored");
}
