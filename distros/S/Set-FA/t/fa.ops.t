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

my($set) = Set::FA -> new(@a, @b, @c);

my($sub_a) = $set -> accept('abbba');
my($sub_b) = $set -> final;

ok($sub_a -> size == @b, 'Sub_a/b sizes match');
ok($sub_a -> includes(@b) == 1, 'Sub_a contains b');
ok($sub_b -> size == @b, 'Sub_b/b sizes match');
ok($sub_b -> includes(@b) == 1, 'Sub_b contains b');

$set -> reset;

$sub_b = $set -> final;

ok($sub_b -> size == scalar @a, 'Sub_b/a sizes match');
ok($sub_b -> includes(@a) == 1, 'Sub_b contains a');

$sub_a = $set -> accept('aaabbaaabdogbbbbbababa');
$sub_b = $set -> final;

ok($sub_a -> size ==  @b + @c, 'Sub_a/b/c sizes match');
ok($sub_a -> includes(@b, @c) == 1, 'Sub_a includes b/c');
ok($sub_b -> size == @b + @c, 'Sub_b/b/c sizes match');
ok($sub_b -> includes(@b, @c) == 1, 'Sub_b includes b/c');

ok($set -> in_state('ping') -> size == 0, 'Set is not in state ping');
ok($set -> in_state('pong') -> size == @a + @b, 'Set a/b is in state pong');
ok($set -> in_state('sad') -> size == 0, 'Set is not in state sad');
ok($set -> in_state('happy') -> size == @c, 'Set c is in state happy');

$sub_a -> reset;
$set -> step('b');

ok($set -> in_state('ping') -> size == @a + @b, 'Set a/c are in state ping');
ok($set -> in_state('pong') -> size == 0, 'Set is not in state pong');
ok($set -> in_state('sad') -> size == @c, 'Set c is in state sad');
ok($set -> in_state('happy') -> size == 0, 'Set is not in state happy');
ok($set -> final -> size == @a, 'Set a final sizes match');
ok($set -> final -> includes(@a) == 1, 'Set final includes a');

done_testing;
