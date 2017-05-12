#!/usr/bin/perl -w
use Test::More tests => 23;
use strict;
our $output;
use SVK::Test;
my ($xd, $svk) = build_test('foo');
$svk->mkdir ('-m', 'init', '//V');
my $tree = create_basic_tree ($xd, '//V');

my ($copath, $corpath) = get_copath ('move');

$svk->checkout ('//V', $copath);

is_sorted_output ($svk, 'move', ["$copath/A/Q", "$copath/A/be", $copath],
	   [__"D   $copath/A/Q",
	    __"D   $copath/A/Q/qu",
	    __"D   $copath/A/Q/qz",
	    __"A   $copath/Q",
	    __"A   $copath/Q/qu",
	    __"A   $copath/Q/qz",
	    __"D   $copath/A/be",
	    __"A   $copath/be"]);

is_output ($svk, 'status', [$copath],
	   [__"D   $copath/A/Q",
	    __"D   $copath/A/Q/qu",
	    __"D   $copath/A/Q/qz",
	    __"D   $copath/A/be",
	    __"A + $copath/Q",
	    __"A + $copath/be"]);

$svk->commit ('-m', 'move in checkout committed', $copath);
is_output ($svk, 'status', [$copath], []);
is_sorted_output ($svk, 'mv', ["$copath/Q/", "$copath/Q-new/"],
	   [__"D   $copath/Q",
	    __"D   $copath/Q/qu",
	    __"D   $copath/Q/qz",
	    __"A   $copath/Q-new",
	    __"A   $copath/Q-new/qu",
	    __"A   $copath/Q-new/qz"]);

is_output ($svk, 'status', [$copath],
	   [__"A + $copath/Q-new",
	    __"D   $copath/Q",
	    __"D   $copath/Q/qu",
	    __"D   $copath/Q/qz"]);

is_output ($svk, 'mv', ["$copath/be", "$copath/Q-new/"],
	   [__"A   $copath/Q-new/be",
	    __"D   $copath/be"]);

is_output ($svk, 'mv', ["$copath/B/fe", "$copath/Q-new/fe"],
	   [__"A   $copath/Q-new/fe",
	    __"D   $copath/B/fe"]);
$svk->revert ("$copath/B/fe", "$copath/Q-new/fe");

is_output ($svk, 'mv', ["$copath/B/fe", "$copath/Q-new/be"],
	   [__"Path $copath/Q-new/be already exists."]);
chdir ("$copath/B");
is_output ($svk, 'mv', ['fe', 'fe.bz'],
	   ['A   fe.bz',
	    'D   fe',
	   ]);
overwrite_file ('new_add', "new file\n");
is_output ($svk, 'add', ['new_add'], ['A   new_add']);
is_output ($svk, 'mv', ['new_add', 'new_add.bz'],
	   [__"new_add is modified."]);
mkdir ('new_dir');
overwrite_file ('new_dir/new_add', "new file\n");
is_output ($svk, 'add', ['new_dir'],
	   [__('A   new_dir'),
	    __('A   new_dir/new_add')]);
is_output ($svk, 'mv', ['new_dir/new_add', 'new_dir/new_add.bz'], [
	__"new_dir is modified.",
	__"new_dir/new_add is modified.",
	]);

$svk->commit ('-m', 'commit everything');
overwrite_file ('new_dir/unknown_file', "unknown file\n");
is_output ($svk, 'mv', ['new_dir', 'new_dir_mv'], 
		[__"unknown_file is unknown."]);
overwrite_file ('new_dir/unknown_file2', "unknown file\n");
is_output ($svk, 'mv', ['new_dir', 'new_dir_mv'], [
		__"unknown_file is unknown.",
		__"unknown_file2 is unknown."]);
unlink('new_dir/unknown_file');
unlink('new_dir/unknown_file2');

is_output ($svk, 'mv', ['new_dir', 'new_dir_mv/blah'], 
		[qr'use -p']);

is_output ($svk, 'mv', [-p => 'new_dir', 'new_dir_mv/blah'], 
		[__('A   new_dir_mv'),
		 __('A   new_dir_mv/blah'),
		 __('A   new_dir_mv/blah/new_add'),
		 __('D   new_dir'),
		 __('D   new_dir/new_add'),
		]);

is_output ($svk, 'st', [],
		[__('A   new_dir_mv'),
		 __('A + new_dir_mv/blah'),
		 __('D   new_dir'),
		 __('D   new_dir/new_add'),
		]);

$svk->commit('-m', 'committed mv -p');

is_output($svk, 'st', [], []);

is_output($svk, 'mv', ['fe.bz' => 'them'],
	  ['A   them',
	   'D   fe.bz']);

is_output($svk, 'st', [],
	  ['A + them',
	   'D   fe.bz']);

$svk->revert('-R');

is_output($svk, 'mv', ['S', 'new_dir_mv' => 'S'],
	  ['Ignoring S as source.',
	   __('A   S/new_dir_mv'),
	   __('A   S/new_dir_mv/blah'),
	   __('A   S/new_dir_mv/blah/new_add'),
	   __('D   new_dir_mv'),
	   __('D   new_dir_mv/blah'),
	   __('D   new_dir_mv/blah/new_add')]);
$svk->revert('-R');
rmtree('S/new_dir_mv'); # XXX: should revert kill unmodified copies ?

is_output($svk, 'mv', ['S', 'new_dir_mv' => 'S/Q'],
	  ['Invalid argument: copying directory S into itself.']);
