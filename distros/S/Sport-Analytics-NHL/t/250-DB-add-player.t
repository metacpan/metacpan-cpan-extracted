#!perl

use v5.10.1;
use strict;
use warnings FATAL => 'all';
use experimental qw(smartmatch);

use Test::More;

use JSON;

use Sport::Analytics::NHL::Vars qw($MONGO_DB);
use Sport::Analytics::NHL::DB;
use Sport::Analytics::NHL::Util qw(:file);
use Sport::Analytics::NHL::Report::Player;

use t::lib::Util;

if ($ENV{HOCKEYDB_NODB} || ! $MONGO_DB) {
	plan skip_all => 'Mongo not defined';
	exit;
}
test_env();
plan tests => 15;

my $db = Sport::Analytics::NHL::DB->new();

my $player;
my $players_c = $db->get_collection('players');

for (8448208,8448321,8470794) {
	$player = Sport::Analytics::NHL::Report::Player->new(
		read_file("t/data/players/$_.json"),
	);
	$player->process();
	Sport::Analytics::NHL::DB::add_new_player($players_c, $player);
	my $player_db = $players_c->find_one({_id => $player->{_id} + 0});
	for my $h (@Sport::Analytics::NHL::DB::PLAYER_HISTORIES) {
		$player->{$h} = [];
	}
	is_deeply($player, $player_db, 'db insert correct');
}

my $player_db = {};
my $player_game = { status => 'C' };
my $game = { start_ts => 10 };
my $team = { name => 'XYZ' };

Sport::Analytics::NHL::DB::set_player_statuses($player_db, $player_game, $game, $team->{name});
is_deeply(
	$player_db,
	{
		statuses => [ {
			start => 10,
			end   => 10,
			team  => 'XYZ',
			status => 'C',
		} ],
	},
	'player statuses correct',
);

$game->{start_ts} = 20;
Sport::Analytics::NHL::DB::set_player_statuses($player_db, $player_game, $game, $team->{name});
is_deeply(
	$player_db,
	{
		statuses => [ {
			start => 10,
			end   => 20,
			team  => 'XYZ',
			status => 'C',
		} ],
	},
	'player statuses updated',
);
$player_game->{status} = 'A';
$game->{start_ts} = 30;
Sport::Analytics::NHL::DB::set_player_statuses($player_db, $player_game, $game, $team->{name});
is_deeply(
	$player_db,
	{
		statuses => [ {
			start => 10,
			end   => 20,
			team  => 'XYZ',
			status => 'C',
		}, {
			start => 30,
			end   => 30,
			team  => 'XYZ',
			status => 'A',
		}, ],
	},
	'player statuses inserted',
);
$team->{name} = 'ABC';
$game->{start_ts} = 40;
Sport::Analytics::NHL::DB::set_player_statuses($player_db, $player_game, $game, $team->{name});
is_deeply(
	$player_db,
	{
		statuses => [ {
			start => 10,
			end   => 20,
			team  => 'XYZ',
			status => 'C',
		}, {
			start => 30,
			end   => 30,
			team  => 'XYZ',
			status => 'A',
		}, {
			start => 40,
			end   => 40,
			team  => 'ABC',
			status => 'A',
		}, ],
	},
	'player statuses inserted',
);
delete $player_db->{statuses};
$player_db->{teams} = [];
Sport::Analytics::NHL::DB::set_player_teams($player_db, $game, $team->{name});
is_deeply(
	$player_db,
	{
		teams => [ {
			start => 40,
			end   => 40,
			team  => 'ABC',
		} ],
		team => 'ABC',
	},
	'player teams correct',
);
$game->{start_ts} = 50;
Sport::Analytics::NHL::DB::set_player_teams($player_db, $game, $team->{name});
is_deeply(
	$player_db,
	{
		teams => [ {
			start => 40,
			end   => 50,
			team  => 'ABC',
		} ],
		team => 'ABC',
	},
	'player teams updated',
);

$game->{start_ts} = 45;
Sport::Analytics::NHL::DB::set_player_teams($player_db, $game, $team->{name});
is_deeply(
	$player_db,
	{
		teams => [ {
			start => 40,
			end   => 50,
			team  => 'ABC',
		} ],
		team => 'ABC',
	},
	'player teams unchanged',
);

$game->{start_ts} = 60;
$team->{name} = 'XYZ';
Sport::Analytics::NHL::DB::set_player_teams($player_db, $game, $team->{name});
is_deeply(
	$player_db,
	{
		teams => [ {
			start => 40,
			end   => 50,
			team  => 'ABC',
		}, {
			start => 60,
			end   => 60,
			team  => 'XYZ',

		} ],
		team => 'XYZ',
	},
	'player teams inserted',
);

delete $player_db->{teams};
delete $player_db->{team};
$player_db->{injury_history} = [];
Sport::Analytics::NHL::DB::set_injury_history($player_db, $game, 'OK');
is_deeply(
	$player_db,
	{
		injury_history => [ {
			start => 60,
			end   => 60,
			status => 'OK',
		} ],
		injury_status => 'OK',
	},
	'player injury_history correct',
);
$game->{start_ts} = 70;
Sport::Analytics::NHL::DB::set_injury_history($player_db, $game, 'OK');
is_deeply(
	$player_db,
	{
		injury_history => [ {
			start => 60,
			end   => 70,
			status => 'OK',
		} ],
		injury_status => 'OK',
	},
	'player injury_history updated',
);

$game->{start_ts} = 65;
Sport::Analytics::NHL::DB::set_injury_history($player_db, $game, 'OK');
is_deeply(
	$player_db,
	{
		injury_history => [ {
			start => 60,
			end   => 70,
			status => 'OK',
		} ],
		injury_status => 'OK',
	},
	'player injury_history unchanged',
);

$game->{start_ts} = 80;
Sport::Analytics::NHL::DB::set_injury_history($player_db, $game, 'IR');
is_deeply(
	$player_db,
	{
		injury_history => [ {
			start => 60,
			end   => 70,
			status => 'OK',
		}, {
			start => 80,
			end   => 80,
			status => 'IR',

		} ],
		injury_status => 'IR',
	},
	'player injury_history inserted',
);

END {
	$players_c->drop() if $players_c;
}
