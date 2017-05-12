#!/usr/bin/perl -w
use Test::More tests => 25;
use strict;
use File::Path;
use Cwd;
use SVK::Test;

my ($xd, $svk) = build_test();
our $output;
our ($copath, $corpath) = get_copath ('smerge-delete');
$svk->mkdir ('-m', 'trunk', '//trunk');
$svk->checkout ('//trunk', $copath);
my ($repospath, undef, $repos) = $xd->find_repos ('//', 1);
my $uuid = $repos->fs->get_uuid;

mkdir "$copath/A";
mkdir "$copath/A/deep";
mkdir "$copath/A/deep/stay";
mkdir "$copath/A/deep/deeper";
mkdir "$copath/B";
overwrite_file ("$copath/A/foo", "foobar\n");
overwrite_file ("$copath/A/deep/foo", "foobar\n");
overwrite_file ("$copath/A/bar", "foobar\n");
overwrite_file ("$copath/A/normal", "foobar\n");
overwrite_file ("$copath/test.pl", "foobarbazzz\n");
$svk->add ("$copath/test.pl", "$copath/A", "$copath/B");
$svk->commit ('-m', 'init', "$copath");

$svk->cp ('-m', 'branch', '//trunk', '//local');

$svk->rm ('-m', 'rm A on trunk', '//trunk/A');
$svk->rm ('-m', 'rm B on trunk', '//trunk/B');
append_file ("$copath/A/foo", "modified\n");
overwrite_file ("$copath/A/unused", "foobar\n");
my $oldwd = getcwd;
chdir ($copath);
is_output ($svk, 'up', [],
	   ["Syncing //trunk(/trunk) in $corpath to 5.",
	    __('C   A'),
	    __('D   A/bar'),
	    __('D   A/deep'),
	    __('C   A/foo'),
	    __('D   A/normal'),
	    __('C   A/unused'),
	    __('D   B'),
	    '3 conflicts found.'
	   ], 'delete entry but modified on checkout');
chdir ($oldwd);
ok (-e "$copath/A/foo", 'local file not deleted');
ok (-e "$copath/A/unused", 'unversioned file not deleted');
ok (!-e "$copath/A/bar", 'delete merged');
ok (!-e "$copath/B/foo", 'unmodified dir deleted');
$svk->resolved ('-R', "$copath/A");
rmtree (["$copath/A"]);
$svk->switch ('//local', $copath);
append_file ("$copath/A/foo", "modified\n");
overwrite_file ("$copath/A/unused", "foobar\n");
is_output ($svk, 'smerge', ['//trunk', $copath],
	   ['Auto-merging (2, 5) /trunk to /local (base /trunk:2).',
	    __"C   $copath/A",
	    __"D   $copath/A/bar",
	    __"D   $copath/A/deep",
	    __"C   $copath/A/foo",
	    __"D   $copath/A/normal",
	    __"C   $copath/A/unused",
	    __"D   $copath/B",
	    "New merge ticket: $uuid:/trunk:5",
	    '3 conflicts found.'
	   ]);
is_output ($svk, 'st', [$copath],
	   [
	    __"C   $copath/A/foo",
	    __"C   $copath/A/unused",
	    __"D   $copath/A/bar",
	    __"D   $copath/A/deep",
	    __"D   $copath/A/deep/deeper",
	    __"D   $copath/A/deep/foo",
	    __"D   $copath/A/deep/stay",
	    __"D   $copath/A/normal",
	    __"C   $copath/A",
	    __"D   $copath/B",
	    __" M  $copath",
	   ]);

ok (-e "$copath/A/unused", 'unversioned file not deleted');
ok (-e "$copath/A/foo", 'local file not deleted');
ok (!-e "$copath/B/foo", 'unmodified dir deleted');
$svk->revert ('-R', $copath);
is_output ($svk, 'st', [$copath],
	   [__"?   $copath/A/unused"]);
append_file ("$copath/A/foo", "modified\n");
overwrite_file ("$copath/A/unused", "foobar\n");
$svk->add ("$copath/A/unused");
$svk->rm ("$copath/A/bar");
$svk->rm ("$copath/A/deep/deeper");
is_output ($svk, 'commit', ['-m', 'local modification', $copath],
	   ['Committed revision 6.']);
is_output ($svk, 'smerge', ['-C', '//trunk', '//local'],
	   ['Auto-merging (2, 5) /trunk to /local (base /trunk:2).',
	    'C   A',
	    'D   A/bar',
	    'D   A/deep',
	    'C   A/foo',
	    'D   A/normal',
	    'C   A/unused',
	    'D   B',
	    "New merge ticket: $uuid:/trunk:5",
	    'Empty merge.',
	    '3 conflicts found.']);

is_output ($svk, 'smerge', ['//trunk', $copath],
	   ['Auto-merging (2, 5) /trunk to /local (base /trunk:2).',
	    __"C   $copath/A",
	    __"D   $copath/A/bar",
	    __"D   $copath/A/deep",
	    __"C   $copath/A/foo",
	    __"D   $copath/A/normal",
	    __"C   $copath/A/unused",
	    __"D   $copath/B",
	    "New merge ticket: $uuid:/trunk:5",
	    '3 conflicts found.']);

is_output ($svk, 'status', [$copath],
	   [__"D   $copath/A/deep",
	    __"D   $copath/A/deep/foo",
	    __"D   $copath/A/deep/stay",
	    __"C   $copath/A/foo",
	    __"D   $copath/A/normal",
	    __"C   $copath/A/unused",
	    __"C   $copath/A",
	    __"D   $copath/B",
	    __" M  $copath"], 'merge partial deletes to checkout');

$svk->revert ('-R', $copath);
$svk->resolved ('-R', $copath);

overwrite_file ("$copath/A/deep/foo", "bah foobar\n");
$svk->commit ('-m', 'local modification', $copath);

is_output ($svk, 'smerge', ['-C', '//trunk', '//local'],
	   ['Auto-merging (2, 5) /trunk to /local (base /trunk:2).',
	    'C   A',
	    'D   A/bar',
	    'C   A/deep',
	    'D   A/deep/deeper',
	    'C   A/deep/foo',
	    'D   A/deep/stay',
	    'C   A/foo',
	    'D   A/normal',
	    'C   A/unused',
	    'D   B',
	    "New merge ticket: $uuid:/trunk:5",
	    'Empty merge.',
	    '5 conflicts found.']);

is_output ($svk, 'smerge', ['//trunk', $copath],
	   ['Auto-merging (2, 5) /trunk to /local (base /trunk:2).',
	    __"C   $copath/A",
	    __"D   $copath/A/bar",
	    __"C   $copath/A/deep",
	    __"D   $copath/A/deep/deeper",
	    __"C   $copath/A/deep/foo",
	    __"D   $copath/A/deep/stay",
	    __"C   $copath/A/foo",
	    __"D   $copath/A/normal",
	    __"C   $copath/A/unused",
	    __"D   $copath/B",
	    "New merge ticket: $uuid:/trunk:5",
	    '5 conflicts found.']);

is_output ($svk, 'status', [$copath],
	   [__"C   $copath/A/deep/foo",
	    __"D   $copath/A/deep/stay",
	    __"C   $copath/A/deep",
	    __"C   $copath/A/foo",
	    __"D   $copath/A/normal",
	    __"C   $copath/A/unused",
	    __"C   $copath/A",
	    __"D   $copath/B",
	    __" M  $copath"], 'merge partial deletes to checkout');

$svk->resolved ('-R', $copath);
$svk->commit ('-m', 'merged', $copath);

$svk->rm ('-m', 'kill test.pl', '//trunk/test.pl');

is_output ($svk, 'smerge', ['//trunk', $copath],
	   ['Auto-merging (5, 9) /trunk to /local (base /trunk:5).',
	    __"D   $copath/test.pl",
	    "New merge ticket: $uuid:/trunk:9"]);
is_output ($svk, 'status', [$copath],
	   [__"D   $copath/test.pl",
	    __" M  $copath"]);

$svk->revert ('-R', $copath);
overwrite_file ("$copath/test.pl", "modified\n");
is_output ($svk, 'smerge', ['//trunk', $copath],
	   ['Auto-merging (5, 9) /trunk to /local (base /trunk:5).',
	    __"C   $copath/test.pl",
	    "New merge ticket: $uuid:/trunk:9",
	    '1 conflict found.']);
$svk->revert ('-R', $copath);

$svk->mkdir ('-m', 'new dir C on trunk', '//trunk/C');
is_output ($svk, 'smerge', ['-m', 'merge down clean', '//trunk', '//local'],
	   ['Auto-merging (5, 10) /trunk to /local (base /trunk:5).',
	    "A   C",
	    "D   test.pl",
	    "New merge ticket: $uuid:/trunk:10",
	    'Committed revision 11.']);

$svk->update ($copath);

my $unversioned = "$copath/C/unversioned.txt";
overwrite_file ($unversioned, "I am here\n");

$svk->rm ('-m', 'rm C on trunk', '//trunk/C');

is_output ($svk, 'smerge', ['//trunk', $copath],
	   ['Auto-merging (10, 12) /trunk to /local (base /trunk:10).',
	    status_native ($copath,
			   'C  ', "C",
			   'C  ', "C/unversioned.txt"),
	    "New merge ticket: $uuid:/trunk:12",
	    '2 conflicts found.']);

ok (-e $unversioned, 'unversioned file not deleted');

$svk->revert(-R => $copath);
$svk->switch('//local', $copath);

$svk->rm("$copath/A/foo");
$svk->mkdir("$copath/A/foo");

$svk->rm(-m => 'hate', '//local/A/foo');

is_output($svk, 'up', [$copath],
	  ['Syncing //local(/local) in '.__($corpath).' to 13.',
	   __("C   $copath/A/foo"),
	   '1 conflict found.']);

