#!perl

use v5.10.1;
use strict;
use warnings FATAL => 'all';
use experimental qw(smartmatch);

use Test::More;

use Sport::Analytics::NHL::Tools qw(read_existing_game_ids);

use t::lib::Util;

test_env();
plan tests => 2;

for my $season (qw(1930 2011)) {
	my $game_ids = read_existing_game_ids($season);
	for my $game_id (keys %{$game_ids}) {
		like($game_id, qr/^$season\d{5}/, 'game id retrieved');
	}
}
