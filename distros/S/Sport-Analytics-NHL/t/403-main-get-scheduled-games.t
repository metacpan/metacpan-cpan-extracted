#!perl

use v5.10.1;
use strict;
use warnings FATAL => 'all';
use experimental qw(smartmatch);

use Test::More;

use JSON;

use Sport::Analytics::NHL::Vars qw($MONGO_DB);
use Sport::Analytics::NHL::Test;
use Sport::Analytics::NHL::Util qw(:file);
use Sport::Analytics::NHL::Tools qw(:schedule);
use Sport::Analytics::NHL;

use t::lib::Util;

test_env();
plan tests => 2;

my $opts = {no_schedule_crawl => 1, start_season => 2016, stop_season => 2017};
my $nhl = Sport::Analytics::NHL->new();
for my $season (1930, 2016) {
	my $schedule_by_date = {};
	my $schedule = decode_json(
		read_file(
			get_schedule_json_file($season)
		)
	);
	arrange_schedule_by_date($schedule_by_date, $schedule);
	$nhl->{db}->insert_schedule(values %{$schedule_by_date}) if $nhl->{db};
}
$ENV{MONGO_DB} = undef;
my @games = Sport::Analytics::NHL::get_nodb_scheduled_games($opts);
for my $game (@games) {
	test_team_id($game->{away}, 'away team ok');
	test_team_id($game->{home}, 'home team ok');
	test_game_id($game->{_id}, 'id is an NHL id', 1);
	test_stage($game->{stage}, 'stage ok');
	test_season($game->{season}, 'season ok');
	test_season_id($game->{season_id}, 'season id ok');
	test_ts($game->{ts}, "$game->{ts} game timestamp ok");
	test_game_id($game->{game_id}, 'game_id is our id');
	test_game_date($game->{date}, 'game date YYYYMMDD');
}
$opts->{force} = 1;
if (! $ENV{HOCKEYDB_NODB} && $MONGO_DB) {
	@games = $nhl->get_db_scheduled_games($opts);
	for my $game (@games) {
		test_team_id($game->{away}, 'away team ok');
		test_team_id($game->{home}, 'home team ok');
		test_game_id($game->{_id}, 'id is an NHL id', 1);
		test_stage($game->{stage}, 'stage ok');
		test_season($game->{season}, 'season ok');
		test_season_id($game->{season_id}, 'season id ok');
		test_ts($game->{ts}, "$game->{ts} game timestamp ok");
		test_game_id($game->{game_id}, 'game_id is our id');
		test_game_date($game->{date}, 'game date YYYYMMDD');
	}
}
summarize_tests();
$nhl->{db}{dbh}->get_collection('schedule')->drop() if $nhl->{db};
