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
plan tests => 2;

my @dates = (19310303, 20161103);
my @games = Sport::Analytics::NHL::Tools::get_games_for_dates_from_fs(@dates);
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

summarize_tests();
