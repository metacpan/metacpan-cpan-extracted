#!perl

use v5.10.1;
use strict;
use warnings FATAL => 'all';
use experimental qw(smartmatch);

use Test::More;

plan tests => 14;

#use Sport::Analytics::NHL::Vars;
use Sport::Analytics::NHL;

my @args = (201020102, 20161110, 2010020140, 2010020103, 201136201, 20120202);
my $games = [];
my $dates = [];

Sport::Analytics::NHL::parse_game_args($games, $dates, @args);
is(scalar(@{$games}), 4, '4 game ids');
is(scalar(@{$dates}), 2, '2 dates');
for my $game (@{$games}) {
	like($game->{season},    qr/^201\d$/, 'season correct');
	like($game->{stage},     qr/^2|3$/,   'stage correct');
	like($game->{season_id}, qr/^\d{4}$/, 'season_id correct');
}
