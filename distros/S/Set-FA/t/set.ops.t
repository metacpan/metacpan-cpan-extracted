#!/usr/bin/env perl

use strict;
use warnings;

use Set::FA;
use Set::FA::Element;

use Test::More;

# --------------------------------------

my(@a) = map
{
	Set::FA::Element -> new
	(
		accepting	=> ['ping'],
		id			=> "a.$_",
		start		=> 'ping',
		transitions	=>
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
		accepting	=> ['pong'],
		id			=> "b.$_",
		start		=> 'ping',
		transitions	=>
		[
			['ping', 'a', 'pong'],
			['ping', '.', 'ping'],
			['pong', 'b', 'ping'],
			['pong', '.', 'pong'],
		],
	)
} (0 .. 4);

my(@c) = map
{
	Set::FA::Element -> new
	(
		accepting	=> ['happy'],
		id			=> "c.$_",
		start		=> 'sad',
		transitions	=>
		[
			['sad',		'dog',	'happy'],
			['sad',		'.',	'sad'],
			['happy',	'.',	'happy'],
		],
	)
} (0 .. 6);

my($set);

ok(defined($set = Set::FA -> new(@a, @b) ) == 1, 'Set defined');
ok($set -> includes(@a, @b, @c) == 0, 'Set does not include a/b/c');

ok($set -> insert(@c) == 7, 'Inserted c into set');
ok($set -> includes(@a, @b, @c) == 1, 'Set includes a/b/c');

my(@z) = ! grep { ! $set -> includes($_) } $set -> members;
ok(@z == 1, 'Set contains all members');
ok($set -> size == 3+5+7, 'Set size is 3+5+7');
ok($set -> id('c.3') -> size == 1, 'Set c.3 size is 1');

ok($set -> remove(@b) == 5, 'Remove 5 members of b');
ok($set -> size == 3+7, 'Set size is 3+7');

$set -> clear;

ok($set -> size == 0, 'Cleared set');

$set -> insert(@a, @b, @c);

my($sub) = Set::FA -> new(@a, @c);

my($bizzaro_set);

ok($set->subset($sub) == 0, 'Set is not a subset of sub');
ok($sub->subset($set) == 1, 'Sub is a subset of itself');
ok($set -> subset($set) == 1, 'Set is a subset of itself');
ok( ($set <= $sub) == 0, 'Set is not a subset of sub');
ok($sub <= $set == 1, 'Sub is a subset of set');
ok($set <= $set == 1, 'Set is a subset of itself');

ok($set->proper_subset($sub) == 0, 'Set is not proper subset of sub');
ok($sub->proper_subset($set) == 1, 'Sub is a proper subset of set');
ok($set->proper_subset($set) == 0, 'Set is not a proper subset of itself');
ok( ($set < $sub) == 0, 'Set is not a proper subset of sub');
ok($sub < $set == 1, 'Sub is a proper subset of set');
ok( ($set < $set) == 0, 'Set is not a proper subset of itself');

ok($set->superset($sub) == 1, 'Set is a superset of sub');
ok( $sub->superset($set) == 0, 'Sub is not a superset of set');
ok($set->superset($set) == 1, 'Set is a superset of itself');
ok($set >= $sub == 1, 'Set is a superset of sub');
ok( ($sub >= $set) == 0, 'Sub is not a superset of sub');
ok($set >= $set == 1, 'Set is a superset of itself');

ok($set->proper_superset($sub) == 1, 'Set is a proper superset of sub');
ok( $sub->proper_superset($set) == 0, 'Sub is not a proper superset of set');
ok( $set->proper_superset($set) == 0, 'Set is not a proper superset of set');
ok($set > $sub == 1, , 'Set is a proper superset of sub');
ok( ($sub > $set) == 0, 'Sub is a not a proper superset of set');
ok( ($set > $set) == 0, 'Set is a not a proper superset of itself');

done_testing;
