#!perl

use v5.10.1;
use strict;
use warnings FATAL => 'all';
use experimental qw(smartmatch);

use Test::More;
use Storable;

use JSON;

use Sport::Analytics::NHL::Vars
	qw($MONGO_DB $IS_AUTHOR $DEFAULT_PLAYERFILE_EXPIRATION);
use Sport::Analytics::NHL::DB;
use Sport::Analytics::NHL::Util qw(:debug :times);
use Sport::Analytics::NHL::Scraper qw(crawl_player);
use Sport::Analytics::NHL::Populator qw(create_player_id_hash);
use Sport::Analytics::NHL::Report::Player;
use Sport::Analytics::NHL;

use t::lib::Util;

if ($ENV{HOCKEYDB_NODB} || ! $MONGO_DB) {
	plan skip_all => 'Mongo not defined';
	exit;
}
plan qw(no_plan);
test_env();
$DEFAULT_PLAYERFILE_EXPIRATION = 0;
my $db = Sport::Analytics::NHL::DB->new();
$ENV{HOCKEYDB_DEBUG} = $IS_AUTHOR;
my $hdb = Sport::Analytics::NHL->new();
my $players_c = $db->get_collection('players');
my $opts = {data_dir => 't/data/'};
for (201120010, 193020010) {
	my @normalized = $hdb->normalize({data_dir => 't/data/'}, $_);
	my $boxscore = retrieve $normalized[0];
	my $PLAYER_IDS = create_player_id_hash($boxscore);
	for my $player_id (keys %{$PLAYER_IDS}) {
		my $team = ${$PLAYER_IDS->{$player_id}}->{team};
		debug "Crawling $player_id";
		my $p_file = $ENV{MONGODB_NONET} || -f "t/data/$player_id.json"
			? "t/data/$player_id.json"
			: crawl_player($player_id, $opts);
		next unless -f $p_file;
		my $player = Sport::Analytics::NHL::Report->new({
			file => $p_file,
			type => 'Player',
		});
		$player->process();
		$db->add_game_player($player, $boxscore, $team, $opts->{force});
		my $player_db = $players_c->find_one({_id => $player->{_id}});
		my $player_game = ${$PLAYER_IDS->{$player_id}};
		push(@{$player->{games}},  $boxscore->{_id} + 0);
		push(@{$player->{starts}}, $boxscore->{_id} + 0)
			if defined $player_game->{start} && $player_game->{start} == 1;
		Sport::Analytics::NHL::DB::set_player_statuses($player, $player_game, $boxscore, $team);
		Sport::Analytics::NHL::DB::set_player_teams($player, $boxscore, $team);
		Sport::Analytics::NHL::DB::set_injury_history($player, $boxscore, 'OK');
		delete $player_db->{updated};
		is_deeply($player_db, $player, 'player inserted');
	}
}
END {
	$players_c->drop() if $players_c;
}
