#!perl

use v5.10.1;
use strict;
use warnings FATAL => 'all';
use experimental qw(smartmatch);

use Test::More tests => 18;

use Sport::Analytics::NHL::Populator qw(create_player_id_hash);

my $boxscore = {
	teams => [
		{
			roster => [
			{ _id => 11, position => 'G' },
			{ _id => 22, position => 'D' },
			{ _id => 33, position => 'R' },
			],
		},
		{
			roster => [
			{ _id => 44, position => 'G' },
			{ _id => 55, position => 'D' },
			{ _id => 66, position => 'R' },
			],
		},
	],
};

my $player_ids = create_player_id_hash($boxscore);
for my $id (keys %{$player_ids}) {
	like($id, qr/^\d{2}$/, 'id two digits expected');
	isa_ok($player_ids->{$id}, 'REF', 'value a reference');
	isa_ok(${$player_ids->{$id}}, 'HASH', 'dereferenced to a hash');
}
