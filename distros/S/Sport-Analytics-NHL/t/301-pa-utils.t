#!perl

use v5.10.1;
use strict;
use warnings FATAL => 'all';
use experimental qw(smartmatch);

use Test::More;

use Sport::Analytics::NHL::PenaltyAnalyzer;
use Sport::Analytics::NHL::Vars qw($DB $MONGO_DB);
use Sport::Analytics::NHL::DB;
use Sport::Analytics::NHL::Test;

if ($ENV{HOCKEYDB_NODB} || ! $MONGO_DB) {
        plan skip_all => 'Mongo not defined';
        exit;
}
plan tests => 4;
$DB = Sport::Analytics::NHL::DB->new();
my $games_c = $DB->get_collection('games');
my $game = $games_c->find_one({_id => 201720010});

$Sport::Analytics::NHL::PenaltyAnalyzer::ON_ICE = [5,5];
Sport::Analytics::NHL::PenaltyAnalyzer::decrease_onice(0);
is_deeply($Sport::Analytics::NHL::PenaltyAnalyzer::ON_ICE, [4,5]);
Sport::Analytics::NHL::PenaltyAnalyzer::increase_onice(1);
is_deeply($Sport::Analytics::NHL::PenaltyAnalyzer::ON_ICE, [4,6]);
Sport::Analytics::NHL::PenaltyAnalyzer::create_player_cache($game);

for my $k (keys %{$Sport::Analytics::NHL::PenaltyAnalyzer::CACHE}) {
	Sport::Analytics::NHL::Test::test_player_id($k, 'player id is key');
	Sport::Analytics::NHL::Test::test_position(
		$Sport::Analytics::NHL::PenaltyAnalyzer::CACHE->{$k},
		'player position in cache',
	);
}
is($TEST_COUNTER->{Curr_Test}, 78, 'full test run');
is($TEST_COUNTER->{Curr_Test}, $TEST_COUNTER->{Test_Results}[0], 'all ok');
