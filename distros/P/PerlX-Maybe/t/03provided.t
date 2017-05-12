use strict;
use warnings;
use Test::More tests => 1;

use PerlX::Maybe ':all';

is_deeply(
	[
		provided 0,     foo   => 1, 6,
		provided 1,     bar   => 2, 7,
		provided 0,     baz   => 3, 8,
		provided undef, quux  => 4, 9,
		provided [],    quuux => 5, 10,
	],
	[
		6,
		bar   => 2, 7,
		8,
		9,
		quuux => 5, 10,
	]
);
