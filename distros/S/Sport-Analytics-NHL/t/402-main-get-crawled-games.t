#!perl

use v5.10.1;
use strict;
use warnings FATAL => 'all';
use experimental qw(smartmatch);

use Test::More;

use Sport::Analytics::NHL::Vars qw($MONGO_DB);
use Sport::Analytics::NHL::Test;
use Sport::Analytics::NHL;

use t::lib::Util;

test_env();
plan tests => 2;

my $opts = ();
my @dates = (19301203, 19691220, 20161205, 20161206);

my $nhl = Sport::Analytics::NHL->new($opts);
my @games = $nhl->get_crawled_games_for_dates($opts, @dates);
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
summarize_tests;

system(qw(rm -rf t/data/1969));
$nhl->{db}{dbh}->get_collection('schedule')->drop() if $MONGO_DB;
