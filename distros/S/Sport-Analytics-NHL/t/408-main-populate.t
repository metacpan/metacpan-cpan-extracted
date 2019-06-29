#!perl

use v5.10.1;
use strict;
use warnings FATAL => 'all';
use experimental qw(smartmatch);

use Test::More;

use JSON;
use Storable;

use Sport::Analytics::NHL::Vars qw($MONGO_DB);
use Sport::Analytics::NHL::Config;
use Sport::Analytics::NHL::Test;
use Sport::Analytics::NHL::Util;
use Sport::Analytics::NHL::Tools;
use Sport::Analytics::NHL;

use t::lib::Util;

test_env();
$ENV{HOCKEYDB_DATA_DIR} = 't/data';
use t::lib::Util;

if ($ENV{HOCKEYDB_NODB} || ! $MONGO_DB) {
	plan skip_all => 'Mongo not defined';
	exit;
}
plan tests => 422;
test_env();
my $nhl = Sport::Analytics::NHL->new();
my $db = $nhl->{db};
my @db_game_ids = $nhl->populate({}, 201120010, 193020010);
my @collections = map($db->get_collection($_), qw(coaches games players locations events STOP FAC PENL GOAL TAKE GIVE PEND PSTR GEND HIT MISS BLOCK SHOT shot_types misses stopreasons penalties strengths zones));
my $games_c   = $nhl->{db}->get_collection('games');
my $players_c = $nhl->{db}->get_collection('players');
for my $db_game_id (@db_game_ids) {
	my $game = $games_c->find_one({_id => $db_game_id + 0 });
	is($game->{_id}, $db_game_id, 'game inserted');
	for (@{$game->{events}}) {
		like($_, qr/^$db_game_id/, 'event converted to ids');
	}
	isa_ok($game->{location}, 'BSON::OID', 'location converted to OID')
		if $db_game_id == 201120010;
	for my $t (0,1) {
		my $team = $game->{teams}[$t];
		isa_ok($team->{coach}, 'BSON::OID', 'coach converted to OID');
		for my $player (@{$team->{roster}}) {
			my $player_db = $players_c->find_one({_id => $player->{_id}+0});
			is(scalar(grep {$_ == $game->{_id}} @{$player_db->{games}}), 1, 'player game registered');
		}
	}
}
END {
	$_->drop() for @collections;
}
