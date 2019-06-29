#!perl

use v5.10.1;
use strict;
use warnings FATAL => 'all';
use experimental qw(smartmatch);

use Test::More tests => 2610;
use Sport::Analytics::NHL::Vars qw($IS_AUTHOR);

$ENV{HOCKEYDB_DEBUG} = $IS_AUTHOR;
use Sport::Analytics::NHL::Report::TV;
use Sport::Analytics::NHL::Test;
use Sport::Analytics::NHL::Config qw(%TEAMS);

my $report;
$report = Sport::Analytics::NHL::Report::TV->new({
	file => 't/data/2011/0002/0010/TV.html',
});

isa_ok($report, 'Sport::Analytics::NHL::Report::TV');
$report->process();
test_boxscore($report, {ti => 1});
is($TEST_COUNTER->{Curr_Test}, 18, 'full test run');
is($TEST_COUNTER->{Curr_Test}, $TEST_COUNTER->{Test_Results}[0], 'all ok');
$BOXSCORE = undef;

$report = Sport::Analytics::NHL::Report::TH->new({
	file => 't/data/2011/0002/0010/TH.html',
});

isa_ok($report, 'Sport::Analytics::NHL::Report::TH');
$report->process();
test_boxscore($report, {ti => 1});
is($TEST_COUNTER->{Curr_Test}, 36, 'full test run');
is($TEST_COUNTER->{Curr_Test}, $TEST_COUNTER->{Test_Results}[0], 'all ok');
$BOXSCORE = undef;

for my $shift (@{$report->{shifts}}) {
	isa_ok($shift, 'HASH', 'shift is a hash');
	like($shift->{player}, qr/^\d{1,2}$/, "player number a number $shift->{player}");
	ok($TEAMS{$shift->{team}}, "valid team shift $shift->{team}");
	like($shift->{start},  qr/^\d{1,4}$/, 'shift start a number');
	like($shift->{finish}, qr/^\d{1,4}$/, 'shift finish a number');
	like($shift->{length}, qr/^\d{1,4}$/, 'shift length a number');
	like($shift->{period}, qr/^\d$/,      'shift period a number');
}
