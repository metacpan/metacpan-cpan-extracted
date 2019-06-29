#!perl

use v5.10.1;
use strict;
use warnings FATAL => 'all';
use experimental qw(smartmatch);

use Test::More;
use Storable;

use JSON;

use Sport::Analytics::NHL::Vars qw($MONGO_DB $IS_AUTHOR);
use Sport::Analytics::NHL::DB;
use Sport::Analytics::NHL::Report::Player;
use Sport::Analytics::NHL;

use t::lib::Util;

if ($ENV{HOCKEYDB_NODB} || ! $MONGO_DB) {
	plan skip_all => 'Mongo not defined';
	exit;
}
plan qw(no_plan);
test_env();

my $db = Sport::Analytics::NHL::DB->new();
$ENV{HOCKEYDB_DEBUG} = $IS_AUTHOR;
my $coaches_c = $db->get_collection('coaches');
my $hdb = Sport::Analytics::NHL->new();
for (201120010, 193020010) {
	my @normalized = $hdb->normalize({data_dir => 't/data/'}, $_);
	my $boxscore = retrieve $normalized[0];

	for my $t (0,1) {
		my $team = $boxscore->{teams}[$t];
		my $coach_db = Sport::Analytics::NHL::DB::add_new_coach(
			$coaches_c, $boxscore, $team
		);
		isa_ok($coach_db->{_id}, 'BSON::OID');
		is($coach_db->{name}, $team->{coach}, 'coach name ok');
		is($coach_db->{team}, $team->{name},  'coach team ok')
			unless $coach_db->{name} eq 'UNKNOWN COACH';
		is($coach_db->{start}, $boxscore->{start_ts}, 'coach start ok');
		is($coach_db->{end},   $boxscore->{start_ts}, 'coach end ok');
		is_deeply($coach_db->{teams}, [{
			start => $boxscore->{start_ts},
			end => $boxscore->{start_ts},
			team => $team->{name},
		}], 'coach team history ok')
			unless $coach_db->{name} eq 'UNKNOWN COACH';
		is_deeply($coach_db->{games}, [ $boxscore->{_id} ], 'game history ok');
	}
	if ($_ == 201120010) {
		$coaches_c->drop();
		$db->add_game_coaches($boxscore);
		for my $t (0,1) {
			my $team = $boxscore->{teams}[$t];
			my $coach_db = $coaches_c->find_one({
				_id => $boxscore->{teams}[$t]{coach},
			});
			isa_ok($coach_db->{_id}, 'BSON::OID');
			is($coach_db->{team}, $team->{name},  'coach team ok');
			is($coach_db->{start}, $boxscore->{start_ts}, 'coach start ok');
			is($coach_db->{end},   $boxscore->{start_ts}, 'coach end ok');
			is_deeply($coach_db->{teams}, [{
				start => $boxscore->{start_ts},
				end => $boxscore->{start_ts},
				team => $team->{name},
			}], 'coach team history ok');
			is_deeply(
				$coach_db->{games}, [ $boxscore->{_id} ], 'game history ok'
			);
		}
		my $boxscore = retrieve $normalized[0];
		$boxscore->{start_ts} += 100000;
		$boxscore->{teams}[0]{name} = 'XYZ';
		$boxscore->{_id}++;
		$db->add_game_coaches($boxscore);
		for my $t (0,1) {
			my $team = $boxscore->{teams}[$t];
			my $coach_db = $coaches_c->find_one({
				_id => $boxscore->{teams}[$t]{coach},
			});
			is($coach_db->{end},   $boxscore->{start_ts}, 'coach end ok');
			is($coach_db->{start}, $boxscore->{start_ts}-100000, 'coach start ok');
			is($coach_db->{team}, $team->{name},  'coach team ok');
			is($coach_db->{teams}[-1]{team}, $team->{name},  'coach team ok');
			is_deeply(
				$coach_db->{games}, [
					$boxscore->{_id}-1,
					$boxscore->{_id},
				], 'game history ok'
			);
			if ($t == 1) {
				is($coach_db->{teams}[0]{start}, $boxscore->{start_ts}-100000, 'coach start ok');
			}
			else {
				is($coach_db->{teams}[-1]{start}, $boxscore->{start_ts}, 'coach new start ok');
				is($coach_db->{teams}[-1]{end}, $boxscore->{start_ts}, 'coach new start ok');
				is(scalar(@{$coach_db->{teams}}), 2,  'coach new team ok');
			}
		}
	}
}


END {
	$coaches_c->drop() if $coaches_c;
}
