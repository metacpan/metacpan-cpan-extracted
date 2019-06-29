#!perl

use v5.10.1;
use strict;
use warnings FATAL => 'all';
use experimental qw(smartmatch);

use Test::More;
use Sport::Analytics::NHL::Vars qw($DB $IS_AUTHOR);
if (! $IS_AUTHOR) {
        plan skip_all => 'Skipping author test';
        exit;
}

use Sport::Analytics::NHL::Util qw(:debug);
use Sport::Analytics::NHL::Tools qw(get_zones get_game_coords_adjust);
plan tests => 7;
$DB = Sport::Analytics::NHL::DB->new();

my $games_c = $DB->get_collection('games');
my $game = $games_c->find_one(
	{_id => 201830187}
);
my $zones = get_zones();
my $goal = Sport::Analytics::NHL::Tools::get_game_first_coord_goal($game, $zones);
is($goal->{team1}, 'VGK', 'first goal found');
my $event = Sport::Analytics::NHL::Tools::get_first_coord_adjust_event($game, $zones);
is($event->{team1}, 'VGK', 'first event found');
my $adjust = get_game_coords_adjust($game, $zones);
is($adjust, -1, 'adjust is -1 for SJS');
$game = $games_c->find_one(
	{_id => 201830186}
);
$adjust = get_game_coords_adjust($game, $zones);
is($adjust, 1, 'adjust is 1 for VGK');
$game = $games_c->find_one(
	{_id => 198720001}
);
$goal = Sport::Analytics::NHL::Tools::get_game_first_coord_goal($game, $zones);
is($goal, undef, 'no coord goal found');
$event = Sport::Analytics::NHL::Tools::get_first_coord_adjust_event($game, $zones);
is($event, undef, 'no coord event found');
$adjust = get_game_coords_adjust($game, $zones);
is($adjust, undef, 'no adjust for old games');
