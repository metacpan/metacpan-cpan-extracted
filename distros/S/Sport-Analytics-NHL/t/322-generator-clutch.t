#!perl

use v5.10.1;
use strict;
use warnings FATAL => 'all';

use Test::More;

use Sport::Analytics::NHL::Generator;
use Sport::Analytics::NHL::Vars  qw($DB $CACHES $MONGO_DB);
use Sport::Analytics::NHL::Util  qw(:debug);
if ($ENV{HOCKEYDB_NODB} || ! $MONGO_DB) {
        plan skip_all => 'Mongo not defined';
        exit;
}
plan tests => 11;

use Sport::Analytics::NHL::DB;
#$ENV{HOCKEYDB_DEBUG} = 1;
$ENV{HOCKEYDB_DRYRUN} = 1;
$DB = Sport::Analytics::NHL::DB->new();

my $games_c = $DB->get_collection('games');
my $game = $games_c->find_one(
	{_id => 201830187}
);
my $GOAL_c  = $DB->get_collection('GOAL');
my @goals = grep {
		! $_->{so}
} $GOAL_c->find({game_id => $game->{_id}})->sort({_id => 1})->all();

my @cg = qw(gtg gtg gtg gtg gtg gtg gtg lgtg geg);
for my $goal (@goals) {
	is(Sport::Analytics::NHL::Generator::get_clutch_type($goal), shift(@cg), 'clutch correct');
}
my $c_g = Sport::Analytics::NHL::Generator::get_clutch_goals($game, @goals);
is_deeply(
	$c_g,
	{ 2018301870320 => 'lgtg', 2018301870436 => 'geg' },
	'clutch goals picked correctly',
);
my $c_h = Sport::Analytics::NHL::Generator::generate_clutch_goals($game);
is_deeply(
	$c_h,
	{ 2018301870320 => 'lgtg', 2018301870436 => 'geg' },
	'clutch goals picked correctly',
);
