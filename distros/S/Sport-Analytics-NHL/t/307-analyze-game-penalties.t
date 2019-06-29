#!perl

use v5.10.1;
use strict;
use warnings FATAL => 'all';
use experimental qw(smartmatch);

use Test::More; 

use Sport::Analytics::NHL::PenaltyAnalyzer;
use Sport::Analytics::NHL::Vars qw($DB $MONGO_DB);
if ($ENV{HOCKEYDB_NODB} || ! $MONGO_DB) {
        plan skip_all => 'Mongo not defined';
        exit;
}
plan tests => 2;
use Sport::Analytics::NHL::DB;
#$ENV{HOCKEYDB_DEBUG} = 1;
$DB = Sport::Analytics::NHL::DB->new();
my $games_c = $DB->get_collection('games');
my $games_i = $games_c->find(
#{season => { '$gte' => 2015 } },
#{_id => 201530141}
);
while (my $game = $games_i->next()) {
	print "$game->{_id}\n";
	eval {
		analyze_game_penalties($game);
	};
	if ($@) {
		$ENV{HOCKEYDB_DEBUG} = 1;
		analyze_game_penalties($game, 1);
		$ENV{HOCKEYDB_DEBUG} = 0;
	}
}
