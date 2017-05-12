#!/usr/bin/perl -w
use Test::More tests => 17;
use strict;
use File::Path;
use Cwd;
use SVK::Test;

my ($xd, $svk) = build_test();
our $output;
my ($copath, $corpath) = get_copath ('smerge-moved');
$svk->mkdir ('-m', 'trunk', '//trunk');
$svk->checkout ('//trunk', $copath);
my ($repospath, undef, $repos) = $xd->find_repos ('//', 1);
my $uuid = $repos->fs->get_uuid;

mkdir "$copath/A";
mkdir "$copath/A/deep";
mkdir "$copath/B";
overwrite_file ("$copath/A/foo", "foobar\n");
overwrite_file ("$copath/A/deep/foo", "foobar\n");
overwrite_file ("$copath/A/bar", "foobar\n");
overwrite_file ("$copath/A/normal", "foobar\n");
overwrite_file ("$copath/test.pl", "foobarbazzz\nend\n");
$svk->add ("$copath/test.pl", "$copath/A", "$copath/B");
$svk->commit ('-m', 'init', "$copath");

$svk->cp ('-m', 'branch', '//trunk', '//local');

$svk->mv ('-m', 'move foo', '//trunk/A/foo', '//trunk/A/foo.new');
$svk->mv ('-m', 'move deep', '//trunk/A/deep', '//trunk/A/deep.new');
$svk->mv ('-m', 'move bar', '//trunk/A/bar', '//trunk/A/deep.new/bar');
$svk->mv ('-m', 'move test.pl on local', '//local/test.pl', '//local/A/deep/test.pl');
$svk->update ($copath);
append_file ("$copath/A/foo.new", "appended\n");
append_file ("$copath/A/deep.new/foo", "appended\n");
append_file ("$copath/A/deep.new/bar", "appended\n");
append_file ("$copath/test.pl", "appended\n");
append_file ("$copath/A/normal", "appended\n");
is_output ($svk, 'commit', ['-m', 'append to moved files', $copath],
	   ['Committed revision 8.']);
is_output ($svk, 'merge', ['-C', '-r7:8', '//trunk', '//local'],
	   ['    A/deep.new - skipped',
	    '    A/deep.new/foo - skipped',
	    '    A/deep.new/bar - skipped',
            'U   A/normal',
	    '    A/foo.new - skipped',
	    '    test.pl - skipped',
	    '5 files skipped, you might want to rerun merge with --track-rename.']);
is_output ($svk, 'merge', ['-C', '--track-rename', '-r7:8', '//trunk', '//local'],
	   ['Collecting renames, this might take a while.',
	    'U   A/deep.new/foo - A/deep/foo',
	    'U   A/deep.new/bar - A/bar',
	    'U   A/normal',
	    'U   A/foo.new - A/foo',
	    'U   test.pl - A/deep/test.pl']);

$svk->switch ('//local', $copath);
is_output ($svk, 'merge', ['-C', '--track-rename', '-r7:8', '//trunk', $copath],
	   ['Collecting renames, this might take a while.',
	    __("U   $copath/A/deep.new/foo")." - A/deep/foo",
	    __("U   $copath/A/deep.new/bar")." - A/bar",
	    __("U   $copath/A/normal"),
	    __("U   $copath/A/foo.new")." - A/foo",
	    __("U   $copath/test.pl")." - A/deep/test.pl"]);

is_output ($svk, 'merge', ['--track-rename', '-r7:8', '//trunk', $copath],
	   ['Collecting renames, this might take a while.',
	    __("U   $copath/A/deep.new/foo")." - A/deep/foo",
	    __("U   $copath/A/deep.new/bar")." - A/bar",
	    __("U   $copath/A/normal"),
	    __("U   $copath/A/foo.new")." - A/foo",
	    __("U   $copath/test.pl")." - A/deep/test.pl"]);
is_output ($svk, 'status', [$copath],
	   [__"M   $copath/A/bar",
	    __"M   $copath/A/deep/foo",
	    __"M   $copath/A/deep/test.pl",
	    __"M   $copath/A/foo",
	    __"M   $copath/A/normal"], 'merge renamed entries to checkout');
$svk->revert ('-R', $copath);
overwrite_file ("$copath/A/deep/test.pl", "foobarbazzz\nfromlocal\nend\n");
is_output ($svk, 'commit', ['-m', 'append to moved files', $copath],
	   ['Committed revision 9.']);
is_output ($svk, 'merge', ['-C', '-r8:9', '//local', '//trunk'],
	   ['    A/deep - skipped',
	    '    A/deep/test.pl - skipped',
	    'Empty merge.',
	    '2 files skipped, you might want to rerun merge with --track-rename.']);
is_output ($svk, 'merge', ['-C', '--track-rename', '-r8:9', '//local', '//trunk'],
	   ['Collecting renames, this might take a while.',
	    'G   A/deep/test.pl - test.pl']);
$svk->switch ('//trunk', $copath);
is_output ($svk, 'merge', ['--track-rename', '-r8:9', '//local', $copath],
	   ['Collecting renames, this might take a while.',
	    __"G   $copath/A/deep/test.pl - test.pl"]);
is_output ($svk, 'status', [$copath],
	   [__"M   $copath/test.pl"], 'merge renamed entries to checkout');
$svk->revert ('-R', $copath);
$svk->cp ('-m', 'new trunk', '//trunk', '//trunk.new');

is_output ($svk, 'merge', ['-C', '--track-rename', '-r8:9', '//local', '//trunk.new'],
	   ['Collecting renames, this might take a while.',
	    'G   A/deep/test.pl - test.pl']);

overwrite_file ("$copath/test.pl", "fnord\nfoobarbazzz\nend\nappended\n");
is_output ($svk, 'commit', ['-m', 'append', $copath],
	   ['Committed revision 11.']);
$svk->switch ('//local', $copath);

is_output ($svk, 'merge', ['--track-rename', '-r10:11', '//trunk', $copath],
	   ['Collecting renames, this might take a while.',
	    __("G   $copath/test.pl")." - A/deep/test.pl"]);

is_output ($svk, 'status', [$copath],
	   [__"M   $copath/A/deep/test.pl"], 'merge renamed entries to checkout');

$svk->revert ('-R', $copath);
$svk->mkdir ('-m', 'new', "//trunk/A/new");
$svk->move ('-m', 'move normal to descent', "//trunk/A/deep.new", '//trunk/A/new/deep.new');
$svk->move ('-m', 'move normal to descent', "//trunk/A/normal", '//trunk/A/new/normal');
$svk->switch ('//trunk', $copath);
append_file ("$copath/A/new/deep.new/bar", "appended after rename\n");
append_file ("$copath/A/new/normal", "appended after rename\n");
is_output ($svk, 'commit', ['-m', 'append', $copath],
	   ['Committed revision 15.']);

is_output ($svk, 'merge', ['-C', '--track-rename', '-r14:15', '//trunk', '//trunk.new'],
	   ['Collecting renames, this might take a while.',
	    "U   A/new/deep.new/bar - A/deep.new/bar",
	    "U   A/new/normal - A/normal"]);

