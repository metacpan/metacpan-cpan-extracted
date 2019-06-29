#!perl

use v5.10.1;
use strict;
use warnings FATAL => 'all';
use experimental qw(smartmatch);

use Test::More tests => 3;
use Sport::Analytics::NHL::Vars qw($IS_AUTHOR);

$ENV{HOCKEYDB_DEBUG} = $IS_AUTHOR;
use Sport::Analytics::NHL::Report::GS;
use Sport::Analytics::NHL::Test;

my $report;
$report = Sport::Analytics::NHL::Report::GS->new({
	file => 't/data/2011/0002/0010/GS.html',
});

isa_ok($report, 'Sport::Analytics::NHL::Report::GS');
$report->process();
test_boxscore($report, {gs => 1});
is($TEST_COUNTER->{Curr_Test}, 82, 'full test run');
is($TEST_COUNTER->{Curr_Test}, $TEST_COUNTER->{Test_Results}[0], 'all ok');
$BOXSCORE = undef;

