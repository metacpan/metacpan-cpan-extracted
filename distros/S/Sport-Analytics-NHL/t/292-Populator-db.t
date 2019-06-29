#!perl

use v5.10.1;
use strict;
use warnings FATAL => 'all';
use experimental qw(smartmatch);

use Test::More;
use List::MoreUtils qw(uniq);
use Storable;

use JSON;

use Sport::Analytics::NHL::Vars qw($MONGO_DB $IS_AUTHOR);
use Sport::Analytics::NHL::DB;
use Sport::Analytics::NHL;
use Sport::Analytics::NHL::Populator;

use t::lib::Util;

if ($ENV{HOCKEYDB_NODB} || ! $MONGO_DB) {
	plan skip_all => 'Mongo not defined';
	exit;
}
plan qw(no_plan);
test_env();
my $db = Sport::Analytics::NHL::DB->new();
my $hdb = Sport::Analytics::NHL->new();
use Data::Dumper;
$ENV{HOCKEYDB_DEBUG} = $IS_AUTHOR;
$ENV{HOCKEYDB_NONET} = 1;
my @collections = map($db->get_collection($_), qw(coaches games players locations events STOP FAC PENL GOAL TAKE GIVE PEND PSTR GEND HIT MISS BLOCK SHOT shot_types misses stopreasons penalties strengths zones));

my $events_c  = $db->get_collection('events');
my $coaches_c = $db->get_collection('coaches');
my $players_c = $db->get_collection('players');
for (201120010, 193020010) {
	my @normalized = $hdb->normalize({data_dir => 't/data/'}, $_);
	my $boxscore = retrieve $normalized[0];
	my $game_id = populate_db($boxscore, {} );
	is($game_id, $_, 'correct game id inserted');
	my $game = $db->get_collection('games')->find_one({_id => $boxscore->{_id}});
	is(scalar(@{$game->{events}}), scalar(@{$boxscore->{events}}), 'all events accounted');
	my $e = 1;
	for (@{$game->{events}}) {
		is($_, $game->{_id}*10000 + $e++, '_id as expected');
		my $_event = $events_c->find_one({event_id => $_ + 0});
		my $event = $db->get_collection($_event->{type})->find_one({
			_id => $_event->{event_id}
		});
		isa_ok($event, 'HASH', 'event accounted correctly');
	}
	for my $t (0,1) {
		my $team = $game->{teams}[$t];
		my $coach = $coaches_c->find_one({_id => $team->{coach}});
			isa_ok($team->{coach}, 'BSON::OID', 'coach registered');
		if ($coach->{name} ne 'UNKNOWN COACH') {
			is(scalar(grep {$_ == $game->{_id}} @{$coach->{games}}), 1, 'coach game registered');
		}
		for my $player (@{$boxscore->{teams}[$t]{roster}}) {
			my $player_db = $players_c->find_one({_id => $player->{_id}+0});
			is(scalar(grep {$_ == $game->{_id}} @{$player_db->{games}}), 1, 'player game registered');
			if ($player->{start} == 1) {
				is(scalar(grep {$_ == $game->{_id}} @{$player_db->{starts}}), 1, 'player startregistered');
			}
			is($player_db->{injury_status}, 'OK', 'injury status OK');
			is($player_db->{team}, $team->{name}, 'team registered');
			is($player_db->{statuses}[-1]{status}, $player->{status}, 'status registered');
			for (qw(teams statuses injury_history)) {
				is($player_db->{$_}[-1]{start}, $game->{start_ts}, "$_ start ok");
			}
		}
	}
	isa_ok($game->{location}, 'BSON::OID', 'location registered')
		if $boxscore->{location};
}
END {
	$_->drop() for @collections;
}
