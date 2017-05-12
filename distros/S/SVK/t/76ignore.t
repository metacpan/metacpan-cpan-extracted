#!/usr/bin/perl -w
use Test::More tests => 6;
use strict;
use SVK::Test;
our $output;
my ($xd, $svk) = build_test();
my ($copath1, $corpath1) = get_copath ('ignore1');
my ($copath2, $corpath2) = get_copath ('ignore2');

# (note: 22status contains ignore tests too)

$svk->checkout('//', $copath1);
$svk->checkout('//', $copath2);

# make sure you can ignore across checkouts: this was an issue while
# developing

overwrite_file("$copath1/foo", "bye");
is_output($svk, 'status', [$copath1],
          [__("?   $copath1/foo")]);

overwrite_file("$copath2/bar", "hi");
is_output($svk, 'status', [$copath2],
          [__("?   $copath2/bar")]);

is_output($svk, 'ignore', ["$copath1/foo", "$copath2/bar"],
          [__(" M  $copath1"),
           __(" M  $copath2")]);

is_output($svk, 'ignore', ["$copath1/foo", "$copath2/bar"],
          [__("Already ignoring '$copath1/foo'"),
           __("Already ignoring '$copath2/bar'")]);

is_output($svk, 'status', [$copath1],
          [__(" M  $copath1")]);

is_output($svk, 'status', [$copath2],
          [__(" M  $copath2")]);
