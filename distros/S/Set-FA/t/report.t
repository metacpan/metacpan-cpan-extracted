#!/usr/bin/env perl

use strict;
use warnings;

use Capture::Tiny 'capture';

use Set::FA::Element;

use Test::More;

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

my($expect) = <<EOS;
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
my(@expect)				= split(/\n/, $expect);
my($stdout, $stderr)	= capture{$dfa -> report};
my(@output)				= split(/\n/, $stdout);

ok($output[5] eq $expect[5], 'Reports as expected');

done_testing;
