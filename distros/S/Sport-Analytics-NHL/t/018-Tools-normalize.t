#!perl

use v5.10.1;
use strict;
use warnings FATAL => 'all';
use experimental qw(smartmatch);

use Test::More tests => 1;

use Sport::Analytics::NHL::Tools;

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

my $positions = set_roster_positions($boxscore);
is_deeply(
	$positions,
	{
		11 => 'G',
		22 => 'D',
		33 => 'R',
		44 => 'G',
		55 => 'D',
		66 => 'R',
	},
	'positions set',
)
