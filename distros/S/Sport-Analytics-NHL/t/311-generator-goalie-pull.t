#!perl

use v5.10.1;
use strict;
use warnings FATAL => 'all';
use experimental qw(smartmatch);

use Test::More;

use Sport::Analytics::NHL::Generator;
use Sport::Analytics::NHL::Vars qw($DB $MONGO_DB);
use Sport::Analytics::NHL::Util qw(:debug);

if ($ENV{HOCKEYDB_NODB} || ! $MONGO_DB) {
        plan skip_all => 'Mongo not defined';
        exit;
}
plan tests => 6;
use Sport::Analytics::NHL::DB;
#$ENV{HOCKEYDB_DEBUG} = 1;
$ENV{HOCKEYDB_DRYRUN} = 1;
$DB = Sport::Analytics::NHL::DB->new();
my $games_c = $DB->get_collection('games');
my $games_i = $games_c->find(
	{_id => 201830187}
);
my $has_pulled_goalie = [0,0,0];

while (my $game = $games_i->next()) {
	my $status = Sport::Analytics::NHL::Generator::guess_pulled_goalie_through_en(
		$game, $has_pulled_goalie
	);
	is($status, 1, 'goalie was pulled');
	is_deeply($has_pulled_goalie, [1, 0, 0], 'pull goalie by team 1');
	my $event = $DB->get_collection('GOAL')->find_one({_id => 2018301870320});
	$has_pulled_goalie = [0,0,0];
	$status = Sport::Analytics::NHL::Generator::guess_pulled_goalie_on_ice(
		$event->{on_ice}, [3,4], $has_pulled_goalie,
	);
	is($status, 1, 'goalie was pulled');
	is_deeply($has_pulled_goalie, [1, 0, 0], 'pull goalie by team 1');
#	$has_pulled_goalie = [0,0,0];
#	$status = Sport::Analytics::NHL::Generator::guess_pulled_goalie_through_events(
#		$game, $has_pulled_goalie,
#	);
#	is($status, 1, 'goalie was pulled');
#	is_deeply($has_pulled_goalie, [1, 0, 0], 'pull goalie by team 1');
	$has_pulled_goalie = [0,0,0];
	$status = Sport::Analytics::NHL::Generator::guess_pulled_goalie_through_toi(
		$game, $has_pulled_goalie,
	);
	is($status, 1, 'goalie was pulled');
	is_deeply($has_pulled_goalie, [1, 0, 0], 'pull goalie by team 1');
	$has_pulled_goalie = Sport::Analytics::NHL::Generator::guess_pulled_goalies(
		$game,
	);
	is_deeply($has_pulled_goalie, [1, 0, 0], 'pull goalie by team 1');
	$has_pulled_goalie = Sport::Analytics::NHL::Generator::get_pulled_goalies(
		$game,
	);
	is_deeply($has_pulled_goalie, [1, 0, 1], 'shift pull goalie by team 1');
}
$games_i = $games_c->find(
	{_id => 201830181}
);
$has_pulled_goalie = [0,0,0];

while (my $game = $games_i->next()) {
	my $status = Sport::Analytics::NHL::Generator::guess_pulled_goalie_through_en(
		$game, $has_pulled_goalie
	);
	is($status, 1, 'goalie was pulled');
	is_deeply($has_pulled_goalie, [1, 0, 0], 'pull goalie by team 1');
}
