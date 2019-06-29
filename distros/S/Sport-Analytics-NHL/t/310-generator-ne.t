#!perl

use v5.10.1;
use strict;
use warnings FATAL => 'all';
use experimental qw(smartmatch);

use Test::More; 

use Sport::Analytics::NHL::Generator;
use Sport::Analytics::NHL::Vars qw($DB $MONGO_DB);
use Sport::Analytics::NHL::Util qw(:debug);

if ($ENV{HOCKEYDB_NODB} || ! $MONGO_DB) {
        plan skip_all => 'Mongo not defined';
        exit;
}
plan tests => 6;
use Sport::Analytics::NHL::DB;
#$ENV{HOCKEYDB_DEBUG} = 1;
$DB = Sport::Analytics::NHL::DB->new();
my $games_c = $DB->get_collection('games');
my $games_i = $games_c->find(
	{_id => 201830186}
);
$ENV{HOCKEYDB_DRYRUN} = 1;
while (my $game = $games_i->next()) {
	my $update = Sport::Analytics::NHL::Generator::generate_ne_goals($game, 0);
	is($update, undef, 'nothing to update');
}
$games_i = $games_c->find(
	{_id => 201830187}
);
while (my $game = $games_i->next()) {
	my $update = Sport::Analytics::NHL::Generator::generate_ne_goals($game, 0);
	is(scalar(@{$update}), 1 , 'one ne');
	is($update->[0], 2018301870320, 'ne id correct');
}
$games_i = $games_c->find(
	{_id => 201830187}
);
$ENV{HOCKEYDB_DRYRUN} = 0;
while (my $game = $games_i->next()) {
	my $update = Sport::Analytics::NHL::Generator::generate_ne_goals($game, 0);
	is(scalar(@{$update}), 1 , 'one ne');
	is($update->[0], 2018301870320, 'ne id correct');
	my $goal = $DB->get_collection('GOAL')->find_one({_id => $update->[0]+0});
	ok($goal->{ne}, 'NE goal updated');
}
