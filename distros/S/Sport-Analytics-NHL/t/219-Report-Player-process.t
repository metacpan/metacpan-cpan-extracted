#!perl

use v5.10.1;
use strict;
use warnings FATAL => 'all';
use experimental qw(smartmatch);

use Test::More tests => 2;

use Sport::Analytics::NHL::Report::Player;
use Sport::Analytics::NHL::Util qw(:file);
use Sport::Analytics::NHL::Test;

#$ENV{HOCKEYDB_DEBUG} = $IS_AUTHOR;
my $report;
for (8448208,8448321,8470794) {
	$report = Sport::Analytics::NHL::Report::Player->new(
		read_file("t/data/players/$_.json"),
	);
	$report->process();
	test_player_report($report);
}
is($TEST_COUNTER->{Curr_Test}, 1064, 'full test run');
is($TEST_COUNTER->{Curr_Test}, $TEST_COUNTER->{Test_Results}[0], 'all ok');
