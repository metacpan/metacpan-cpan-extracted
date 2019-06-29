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
plan tests => 5;

use Sport::Analytics::NHL::DB;
#$ENV{HOCKEYDB_DEBUG} = 1;
$ENV{HOCKEYDB_DRYRUN} = 1;
$DB = Sport::Analytics::NHL::DB->new();
my $games_c = $DB->get_collection('games');
my $game = $games_c->find_one(
	{_id => 194720007}
);

my @fights = Sport::Analytics::NHL::Generator::generate_fighting_majors($game, 1);
for my $fight (@fights) {
	is(scalar(@{$fight}), 2, '2 participants in a fight');
	isnt($fight->[0]{team1}, $fight->[1]{team}, 'two different teams');
	is($fight->[0]{ts}, $fight->[1]{ts}, 'same timestamp');
	is($fight->[0]{length}, 5, 'Fighting major F1');
	is($fight->[1]{length}, 5, 'Fighting major F2');
}

