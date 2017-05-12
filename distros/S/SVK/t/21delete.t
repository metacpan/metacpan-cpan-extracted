#!/usr/bin/perl -w
use Test::More tests => 49;
use strict;
use File::Path;
use SVK::Test;
our $output;
my ($xd, $svk) = build_test();
my ($copath, $corpath) = get_copath ('delete');
my ($repospath, undef, $repos) = $xd->find_repos ('//', 1);
$svk->checkout ('//', $copath);

is_output_like ($svk, 'delete', [], qr'SYNOPSIS', 'delete - help');

chdir ($copath);
mkdir ('A');
mkdir ('A/deep');
overwrite_file ("A/foo", "foobar");
overwrite_file ("A/bar", "foobar");
overwrite_file ("A/deep/baz", "foobar");

$svk->add ('A');
is_output ($svk, 'rm', ['A/foo'],
	   [__"A/foo is scheduled; use '--force' to go ahead."]);
chdir('A');
is_output ($svk, 'rm', ['foo'],
	   [__"../A/foo is scheduled; use '--force' to go ahead."]);
chdir('..');
$svk->commit ('-m', 'init');

append_file ('A/foo', "modified.\n");
is_output ($svk, 'rm', ['A/foo'],
	   [__"A/foo is modified; use '--force' to go ahead."]);
$svk->revert ('A/foo');
is_output ($svk, 'delete', ['A/foo'],
	   [__('D   A/foo')], 'delete - file');
ok (!-e 'A/foo', 'delete - copath deleted');
is_output ($svk, 'status', [],
	   [__('D   A/foo')], 'delete - status');

is_output ($svk, 'delete', ['A/foo'],
	   [__('D   A/foo')], 'delete file again');
	   
$svk->revert ('-R', '.');

append_file ('A/foo', "modified.\n");
is_output ($svk, 'rm', ['A/foo'],
	   [__"A/foo is modified; use '--force' to go ahead."]);
is_output ($svk, 'rm', ['--force', 'A/foo'],
	   [__('D   A/foo')], 'delete - file');
ok (!-e 'A/foo', 'delete - copath deleted');
is_output ($svk, 'status', [],
	   [__('D   A/foo')], 'delete - status');
is_output ($svk, 'delete', ['A/foo'],
	   [__('D   A/foo')], 'delete file again');

$svk->revert ('-R', '.');

append_file ('A/foo', "modified.\n");
is_output ($svk, 'rm', ['A'],
	   [__"A/foo is modified; use '--force' to go ahead."]);
is_sorted_output ($svk, 'rm', ['--force', 'A'], [
	__('D   A'),
	__('D   A/bar'),
	__('D   A/deep'),
	__('D   A/deep/baz'),
	__('D   A/foo'),
], 'delete - file');
ok (!-e 'A/', 'delete - copath deleted');
is_output ($svk, 'status', [], [
	__('D   A'),
	__('D   A/bar'),
	__('D   A/deep'),
	__('D   A/deep/baz'),
	__('D   A/foo'),
], 'delete - status');

is_output ($svk, 'delete', ['A'], [
	__('D   A'),
	__('D   A/bar'),
	__('D   A/deep'),
	__('D   A/deep/baz'),
	__('D   A/foo'),
], 'delete file again');

$svk->revert ('-R', '.');

# now try deleting directory with unknown file in it
overwrite_file ('A/quux', "modified.\n");
is_output ($svk, 'rm', ['A'],
	   [__"A/quux is not under version control; use '--force' to go ahead."]);
is_sorted_output ($svk, 'rm', ['--force', 'A'], [
	__('D   A'),
	__('D   A/bar'),
	__('D   A/deep'),
	__('D   A/deep/baz'),
	__('D   A/foo'),
	__('D   A/quux'),
], 'delete - file');
ok (!-e 'A/', 'delete - copath deleted');
is_output ($svk, 'status', [], [
	__('D   A'),
	__('D   A/bar'),
	__('D   A/deep'),
	__('D   A/deep/baz'),
	__('D   A/foo'),
], 'delete - status');

is_output ($svk, 'delete', ['A'], [
	__('D   A'),
	__('D   A/bar'),
	__('D   A/deep'),
	__('D   A/deep/baz'),
	__('D   A/foo'),
], 'delete file again');

$svk->revert ('-R', '.');

# now try deleting directory with added file in it
overwrite_file ('A/quux', "modified.\n");
$svk->add('A/quux');
is_output ($svk, 'rm', ['A'],
	   [__"A/quux is scheduled; use '--force' to go ahead."]);
is_sorted_output ($svk, 'rm', ['--force', 'A'], [
	__('D   A'),
	__('D   A/bar'),
	__('D   A/deep'),
	__('D   A/deep/baz'),
	__('D   A/foo'),
	__('D   A/quux'),
], 'delete - file');
ok (!-e 'A/', 'delete - copath deleted');
is_output ($svk, 'status', [], [
	__('D   A'),
	__('D   A/bar'),
	__('D   A/deep'),
	__('D   A/deep/baz'),
	__('D   A/foo'),
], 'delete - status');

is_output ($svk, 'delete', ['A'], [
	__('D   A'),
	__('D   A/bar'),
	__('D   A/deep'),
	__('D   A/deep/baz'),
	__('D   A/foo'),
], 'delete file again');

$svk->revert ('-R', '.');

# now try copying directory and deleting the copy
$svk->copy('A', 'B');
is_output ($svk, 'rm', ['B'],
	   [__"B is scheduled; use '--force' to go ahead."]);
is_sorted_output ($svk, 'rm', ['--force', 'B'], [
	__('D   B'),
	__('D   B/bar'),
	__('D   B/deep'),
	__('D   B/deep/baz'),
	__('D   B/foo'),
], 'delete - file');
ok (!-e 'B/', 'delete - copath deleted');
is_output ($svk, 'status', [], [
], 'delete - status');

is_output ($svk, 'delete', ['B'], [
	__"Unknown target: B."
], 'delete file again');

$svk->revert ('-R', '.');

# now try copying directory and deleting the copy
$svk->copy('A/bar', 'A/deep');
overwrite_file ('A/deep/baz', "modified.\n");
overwrite_file ('A/deep/quux', "created.\n");
overwrite_file ('A/deep/quux2', "created.\n");
$svk->add('A/deep/quux2');
is_output ($svk, 'rm', ['A'], [
	__("A/deep/quux is not under version control,"),
	__("A/deep/baz is modified,"),
	__("A/deep/bar is scheduled,"),
	__("A/deep/quux2 is scheduled; use '--force' to go ahead.")]);
is_sorted_output ($svk, 'rm', ['--force', 'A'], [
	__('D   A'),
	__('D   A/bar'),
	__('D   A/deep'),
	__('D   A/deep/bar'),
	__('D   A/deep/baz'),
	__('D   A/deep/quux'),
	__('D   A/deep/quux2'),
	__('D   A/foo'),
], 'delete - file');
$svk->revert ('-R', '.');


unlink ('A/foo');
is_output ($svk, 'delete', ['A/foo'],
	   [__('D   A/foo')], 'delete - file already unlinked');
is_output ($svk, 'status', [],
	   [__('D   A/foo')], 'delete - status');

$svk->revert ('-R', '.');
is_output ($svk, 'delete', ['A/foo', 'A/bar'],
		[__('D   A/foo'),
		 __('D   A/bar')]);
$svk->revert ('-R', '.');

is_output ($svk, 'delete', ['--keep-local', 'A/foo'],
	   [__('D   A/foo')], '');
ok (-e 'A/foo', 'copath not deleted');
is_output ($svk, 'status', [],
	   [__('D   A/foo')], 'copath not deleted');

is_output ($svk, 'delete', ["$corpath/A/foo"],
	   [__("D   $corpath/A/foo")], 'delete - file - abspath');
$svk->revert ('-R', '.');

overwrite_file ("A/deep/baz~", "foobar");
is_output ($svk, 'delete', ['A/deep'],
	   [map __($_),
	    'D   A/deep',
	    'D   A/deep/baz'], 'delete - ignore files');

is_output ($svk, 'delete', ['-m', 'rm directly', '//A/deep'],
	  ['Committed revision 2.'], 'rm directly');

$svk->mkdir (-m => 'something', '//A/something');

$svk->up;
rmtree ('A/something');
is_output ($svk, 'st', [],
	   [__('!   A/something')]);
is_output ($svk, 'rm', ['A/something'],
	   [__('D   A/something')]);

overwrite_file ('A/stalled', "foo");
is_output ($svk, 'rm', ['A/stalled'],
	   [__("A/stalled is not under version control; use '--force' to go ahead.")]);

is_output ($svk, 'rm', [-m => 'fnord', '//A/something', '//A/bar'],
	   ['Committed revision 4.']);

is_output ($svk, 'rm', ['A/deep', '//A/bad'],
	   [qr'not supported']);

