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
plan tests => 7;

use Sport::Analytics::NHL::DB;
#$ENV{HOCKEYDB_DEBUG} = 1;
$ENV{HOCKEYDB_DRYRUN} = 1;
$DB = Sport::Analytics::NHL::DB->new();

my $games_c = $DB->get_collection('games');
my $game = $games_c->find_one(
	{_id => 201830187}
);

my $breaks = Sport::Analytics::NHL::Generator::generate_gamedays($game);
is_deeply($breaks, [1,1], 'breaks correct');
$game = $games_c->find_one(
	{_id => 201820001}
);
$breaks = Sport::Analytics::NHL::Generator::generate_gamedays($game);
is_deeply($breaks, [30,30], 'breaks correct');
$game = $games_c->find_one(
	{_id => 201821000}
);
$breaks = Sport::Analytics::NHL::Generator::generate_gamedays($game);
is_deeply($breaks, [2,1], 'breaks correct');
