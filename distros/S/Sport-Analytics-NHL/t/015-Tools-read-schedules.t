#!perl

use v5.10.1;
use strict;
use warnings FATAL => 'all';
use experimental qw(smartmatch);

use Test::More;

use JSON qw(decode_json);

use Sport::Analytics::NHL::Tools qw(:schedule);
use Sport::Analytics::NHL::Test;

use t::lib::Util;

test_env();
$ENV{MONGO_DB} = undef;
plan tests => 2706;

my $opts = {start_season => 2016, stop_season => 2017};
my $schedules = read_schedules($opts);
for my $season (keys %{$schedules}) {
	for my $game (@{$schedules->{$season}}) {
		$Sport::Analytics::NHL::Test::DO_NOT_DIE = 1;
		test_game_id($game->{id}, 'schedule game id', 1);
		$Sport::Analytics::NHL::Test::DO_NOT_DIE = 0;
		$Sport::Analytics::NHL::Test::TEST_ERRORS = {};
		test_team_code($game->{h},  'home');
		test_team_code($game->{a},  'away');
		like($game->{est}, qr/^\d{8} \d{2}:\d{2}:\d{2}/, 'estimate a timestamp');
	}
}
