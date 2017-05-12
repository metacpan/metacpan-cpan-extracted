#!/usr/bin/env perl

use strict;
use warnings;

use Set::FA::Element;

# --------------------------------------

my($dfa) = Set::FA::Element -> new
(
	accepting	=> ['baz'],
	maxlevel	=> 'debug',
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

print "Got: \n";
$dfa -> report;

print "Expected: \n", <<EOS;
Entered report()
State Transition Table
State: bar
Rule => Next state
/a/ => foo
/b/ => bar
/c/ => baz
State: baz. This is an accepting state
Rule => Next state
/./ => baz
State: foo. This is the start state
Rule => Next state
/b/ => bar
/./ => foo
EOS
