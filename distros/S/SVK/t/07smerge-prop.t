#!/usr/bin/perl -w
use strict;
use Test::More;
use SVK::Test;
our ($output, $answer);
plan tests => 12;

# build another tree to be mirrored ourself
my ($xd, $svk) = build_test();
my ($repospath, undef, $repos) = $xd->find_repos ('//', 1);
my $uuid = $repos->fs->get_uuid;
$svk->mkdir ('-m', 'init', '//trunk');
my $tree = create_basic_tree ($xd, '//trunk');

my ($copath, $corpath) = get_copath ('smerge-prop');

$svk->cp ('-m', 'local branch', '//trunk', '//local');

$svk->ps ('-m', 'add prop on trunk', 'smerge-prop', 'new prop on trunk', '//trunk/A/be');
is_output ($svk, 'smerge', ['-C', '-t', '//local'],
	   ['Auto-merging (3, 5) /trunk to /local (base /trunk:3).',
	    ' U  A/be',
	    "New merge ticket: $uuid:/trunk:5"]);

$svk->ps ('-m', 'add prop on local', 'smerge-prop', 'new prop on trunk', '//local/A/be');
is_output ($svk, 'smerge', ['-C', '-t', '//local'],
	   ['Auto-merging (3, 5) /trunk to /local (base /trunk:3).',
	    ' g  A/be',
	    "New merge ticket: $uuid:/trunk:5"]);

# test prop merge without base
$svk->ps ('-m', 'add prop on local', 'smerge-prop', 'new prop on local', '//local/A/be');
is_output ($svk, 'smerge', ['-C', '-t', '//local'],
	   ['Auto-merging (3, 5) /trunk to /local (base /trunk:3).',
	    ' C  A/be',
	    "New merge ticket: $uuid:/trunk:5",
	    'Empty merge.',
	    '1 conflict found.']);

is_output ($svk, 'smerge', ['-m', 'merge down', '-t', '//local'],
	   ['Auto-merging (3, 5) /trunk to /local (base /trunk:3).',
	    ' C  A/be',
	    "New merge ticket: $uuid:/trunk:5",
	    'Empty merge.',
	    '1 conflict found.']);

$ENV{SVKRESOLVE} = ''; $answer = 't';
is_output ($svk, 'smerge', ['-m', 'merge down', '-t', '//local'],
	   ['Auto-merging (3, 5) /trunk to /local (base /trunk:3).',
	    ' G  A/be',
	    "New merge ticket: $uuid:/trunk:5",
	    'Committed revision 8.']);

is_output ($svk, 'pg', ['smerge-prop', "//local/A/be"],
	   ['new prop on trunk'], 'theirs accepted');

# test prop merge on checkout

$svk->checkout ('//local' => $copath);
$svk->ps (-m => 'foo', newprop => 'newvalue', '//local/A');
$svk->ps (newprop => 'newvalue', "$copath/A");
is_output ($svk, 'update', [-C => $copath],
	   ["Syncing //local(/local) in $corpath to 9.",
	    __" g  $copath/A"]);
is_output ($svk, 'st',  [$copath],
	   [__" M  $copath/A"], 'prop not cleared after update -C');
is_output ($svk, 'update', [$copath],
	   ["Syncing //local(/local) in $corpath to 9.",
	    __" g  $copath/A"]);
is_output ($svk, 'st',  [$copath], [], 'prop merged, checkout unscheduled');
$svk->ps (-m => 'foo', newprop2 => 'newvalue2', '//local/A');
$svk->ps (newprop2 => 'newvalue2', "$copath/A");
$svk->ps (newprop3 => 'newvalue3', "$copath/A");
is_output ($svk, 'update', [$copath],
	   ["Syncing //local(/local) in $corpath to 10.",
	    __" g  $copath/A"]);
is_output ($svk, 'st',  [$copath],
	   [__" M  $copath/A"], 'prop merged, but still something left');

# XXX: test prop merge with base
