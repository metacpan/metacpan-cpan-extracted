#!perl

use v5.10.1;
use strict;
use warnings FATAL => 'all';
use experimental qw(smartmatch);

use Test::More;

use JSON;

use Sport::Analytics::NHL::Vars qw($MONGO_DB);
use Sport::Analytics::NHL::DB;
use Sport::Analytics::NHL::Test;
use Sport::Analytics::NHL::Tools qw(:schedule);
use Sport::Analytics::NHL::Util qw(:file);

use t::lib::Util;

if ($ENV{HOCKEYDB_NODB} || ! $MONGO_DB) {
	plan skip_all => 'Mongo not defined';
	exit;
}
test_env();
plan tests => 2;

my $db = Sport::Analytics::NHL::DB->new();
for my $season (1930, 2016) {
	my $schedule_by_date = {};
	my $schedule = decode_json(
		read_file(
			get_schedule_json_file($season)
		)
	);
	arrange_schedule_by_date($schedule_by_date, $schedule);
	$db->insert_schedule(values %{$schedule_by_date});
	my $schedule_i =  $db->{dbh}->get_collection('schedule')->find();
	while (my $game = $schedule_i->next()) {
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
$db->{dbh}->get_collection('schedule')->drop();

summarize_tests();
