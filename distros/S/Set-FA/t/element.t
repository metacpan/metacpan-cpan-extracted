#!/usr/bin/env perl

use strict;
use warnings;

use Set::FA::Element;

use Test::More;

# --------------------------------------

my($dfa) = Set::FA::Element -> new
(
	accepting	=> ['baz'],
	start		=> 'foo',
	transitions	=>
	[
		['foo', 'b', 'bar'],
		['foo', '.', 'foo'],
		['bar', 'a', 'foo'],
		['bar', 'b', 'bar'],
		['bar', 'c', 'baz'],
		['baz', '.', 'baz'],
	],
);

ok($dfa -> isa('Set::FA::Element') == 1, 'Object isa Set::FA::Element');
ok($dfa -> state('bar') == 1, 'State is bar');
ok(! $dfa -> state('new') == 1, 'State is not new');
ok($dfa -> final('baz') == 1, 'baz is an acceptor');
ok($dfa -> final('bar') == 0, 'bar is not an acceptor');

ok($dfa -> step('a') eq '', 'step(a) returned nothing');
ok($dfa -> state eq  'foo', 'State is foo');
ok($dfa -> final == 0, 'foo is not an acceptor');

ok($dfa -> step('aa') eq 'a', 'step(aa) returned a');
ok($dfa -> state eq 'foo', 'State is foo');
ok($dfa -> final == 0, 'foo is not an acceptor');

ok($dfa -> step('bar') eq 'ar', 'step(bar) returned ar');
ok($dfa -> state eq 'bar', 'State is bar');
ok($dfa -> final == 0, 'bar is not an acceptor');

ok($dfa -> step('c') eq '', 'step(c) returned nothing');
ok($dfa -> state eq 'baz', 'State is baz');
ok($dfa -> final == 1, 'baz is an acceptor');

ok($dfa -> step('cca') eq 'ca', 'step(cca) returned ca');
ok($dfa -> state eq 'baz', 'State is baz');
ok($dfa -> final == 1, 'baz is an acceptor');

ok($dfa -> step('boo') eq 'oo', 'step(boo) returned oo');
ok($dfa -> state eq 'baz', 'State is baz');
ok($dfa -> final == 1, 'baz is an acceptor');

ok($dfa -> reset eq 'foo', 'reset returns initial state');
ok($dfa -> state eq 'foo', 'reset returned initial state');

ok($dfa -> advance('a') eq 'foo', 'advance(a) leads to state foo');
ok($dfa -> advance('ac') eq 'foo', 'advance(ac) leads to state foo');
ok($dfa -> advance('aaaccb') eq 'bar', 'advance(aaaccb) leads to state bar');
ok($dfa -> advance('acacbcaaba') eq 'baz', 'advance(acacbcaaba) leads to state baz');

my($entry_count)	= 0;
my($exit_count)		= 0;
$dfa				= Set::FA::Element -> new
(
	accepting	=> ['baz'],
	actions		=>
	{
		bar =>
		{
			entry	=> sub { $entry_count++; },
			exit	=> sub { $exit_count++; }
		}
	},
	start		=> 'foo',
	transitions	=>
	[
		['foo', 'b', 'bar'],
		['foo', '.', 'foo'],
		['bar', 'a', 'foo'],
		['bar', 'b', 'bar'],
		['bar', 'c', 'baz'],
		['baz', '.', 'baz'],
	],
);

ok($dfa -> accept('abababa') == 0, 'accept(abababa) does not lead to an acceptor');
ok($entry_count == 3, 'entry_count is 3');
ok($exit_count == 3, 'exit_count is 3');

$dfa -> reset;

ok($dfa -> accept('bbbc') == 1, 'accept(bbbc) leads to an acceptor');
ok($entry_count == 4, 'entry_count is 4');
ok($exit_count == 4, 'exit_count is 4');

$dfa -> reset;

ok($dfa -> accept('cccbbbaaa') == 0, 'accept(cccbbbaaa) does not lead to an acceptor');
ok($entry_count == 5, 'entry_count is 5');
ok($exit_count == 5, 'exit_count is 5');

$dfa -> reset;

ok($dfa -> accept('ababababc') == 1, 'accept(ababababc) leads to an acceptor');
ok($entry_count == 9, 'entry_count is 9');
ok($exit_count == 9, 'exit_count is 9');

done_testing;
