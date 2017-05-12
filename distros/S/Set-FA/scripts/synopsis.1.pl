#!/usr/bin/perl

use strict;
use warnings;

use Set::FA;
use Set::FA::Element;

# --------------------------

my(@a) = map
{
	Set::FA::Element -> new
	(
		accepting   => ['ping'],
		id          => "a.$_",
		start       => 'ping',
		transitions =>
		[
			['ping', 'a', 'pong'],
			['ping', '.', 'ping'],
			['pong', 'b', 'ping'],
			['pong', '.', 'pong'],
		],
	)
} (0 .. 2);

my(@b) = map
{
	Set::FA::Element -> new
	(
		accepting   => ['pong'],
		id          => "b.$_",
		start       => 'ping',
		transitions =>
		[
			['ping', 'a', 'pong'],
			['ping', '.', 'ping'],
			['pong', 'b', 'ping'],
			['pong', '.', 'pong'],
		],
	)
} (0 .. 4);

my($set)   = Set::FA -> new(@a, @b);
my($sub_a) = $set -> accept('aaabbaaabdogbbbbbababa');
my($sub_b) = $set -> final;

print 'Size of $sub_a: ', $sub_a -> size, ' (expect 3). ',
	'Size of @a: ', scalar @a, ' (expect 3). ',
	'Size of $sub_b: ', $sub_b -> size, ' (expect 5). ',
	'Size of @b: ', scalar @b, ' (expect 5). ', "\n",
