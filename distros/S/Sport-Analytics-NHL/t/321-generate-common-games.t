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
plan tests => 1027;

use Sport::Analytics::NHL::DB;
#$ENV{HOCKEYDB_DEBUG} = 1;
$ENV{HOCKEYDB_DRYRUN} = 1;
$DB = Sport::Analytics::NHL::DB->new();

my $games_c = $DB->get_collection('games');
my $game = $games_c->find_one(
	{_id => 201830187}
);

my $update = Sport::Analytics::NHL::Generator::generate_common_games($game, 1);

is(scalar(@{$update}), 342, '342 combinations');
my $cache = {};
for my $id (@{$update}) {
	is(length($id), 14, 'double player id');
	like($id, qr/^8\d{6}8\d{6}$/, 'double 8-number');
	ok(! $cache->{$id}, 'unique');
	$cache->{$id} = 1;
}
