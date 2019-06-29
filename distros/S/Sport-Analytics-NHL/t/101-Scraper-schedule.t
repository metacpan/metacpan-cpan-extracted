#!perl

use v5.10.1;
use strict;
use warnings FATAL => 'all';
use experimental qw(smartmatch);

use Test::More;

use Sport::Analytics::NHL::Scraper qw(crawl_schedule);
use Sport::Analytics::NHL::Test;

use t::lib::Util;

if ($ENV{HOCKEYDB_NONET}) {
	plan skip_all => 'No network connection requested';
	exit;
}
plan tests => 4;
test_env();

my $opts = {start_season => 2016, stop_season => 2017};

$ENV{HOCKEYDB_DATA_DIR} = 't/tmp/data';

my $schedules = crawl_schedule($opts);
for my $season (keys %{$schedules}) {
	for my $game (@{$schedules->{$season}}) {
		$Sport::Analytics::NHL::Test::DO_NOT_DIE = 1;
		test_game_id($game->{id}, 'schedule game id', 1);
		$Sport::Analytics::NHL::Test::DO_NOT_DIE = 0;
		$Sport::Analytics::NHL::Test::TEST_ERRORS = {};
		next if $Sport::Analytics::NHL::Test::MESSAGE =~ /game id/;
		test_team_id($game->{h},  'home');
		test_team_id($game->{a},  'away');
		like($game->{est}, qr/^\d{8} \d{2}:\d{2}:\d{2}/, 'estimate a timestamp');
	}
}
is($TEST_COUNTER->{Curr_Test}, 16236, 'full test run');
is($TEST_COUNTER->{Test_Results}[0], 16202, 'all expected ok');

$opts = {start_season => 1930, stop_season => 1930};
$schedules = crawl_schedule($opts);
for my $season (keys %{$schedules}) {
	isa_ok($schedules->{$season}{dates}, 'ARRAY', 'old schedule array of dates');
	ok(scalar(@{$schedules->{$season}{dates}}), 'and it is not empty');
}
system(qw(rm -rf t/tmp/data));

