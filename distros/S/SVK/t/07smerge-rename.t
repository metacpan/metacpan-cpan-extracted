#!/usr/bin/perl -w
use Test::More tests => 4;
use strict;
use File::Path;
use Cwd;
use SVK::Test;

my ($xd, $svk) = build_test();
our $output;
my ($copath, $corpath) = get_copath();
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
is_output ($svk, 'smerge', ['--track-rename', '-C', '//trunk', '//local'],
	   ['Auto-merging (2, 8) /trunk to /local (base /trunk:2).',
	    'Collecting renames, this might take a while.',
	    'A + A/deep.new',
	    'U   A/deep.new/foo',
	    'A + A/deep.new/bar',
	    'U   A/normal',
	    'A + A/foo.new',
	    'D   A/bar',
	    'C   A/deep',
	    'D   A/deep/foo',
	    'C   A/deep/test.pl',
	    'D   A/foo',
	    'U   test.pl - A/deep/test.pl',
	    qr'New merge ticket: .*:/trunk:8',
	    'Empty merge.',
	    '2 conflicts found.']);

$ENV{SVKRESOLVE} = 's';
is_output ($svk, 'smerge', ['--track-rename', '//trunk', '//local', -m => 'merge with renames'],
	   ['Auto-merging (2, 8) /trunk to /local (base /trunk:2).',
	    'Collecting renames, this might take a while.',
	    'A + A/deep.new',
	    'U   A/deep.new/foo',
	    'A + A/deep.new/bar',
	    'U   A/normal',
	    'A + A/foo.new',
	    'D   A/bar',
	    'C   A/deep',
	    'D   A/deep/foo',
	    'C   A/deep/test.pl',
	    'D   A/foo',
	    'U   test.pl - A/deep/test.pl',
	    qr'New merge ticket: .*:/trunk:8',
	    'Empty merge.',
	    '2 conflicts found.']);

my ($lcopath, $lcorpath) = get_copath ('smerge-rename-moved');
$svk->checkout ('//local', $lcopath);
is_output ($svk, 'smerge', ['--track-rename', '//trunk', $lcopath],
	   ['Auto-merging (2, 8) /trunk to /local (base /trunk:2).',
	    'Collecting renames, this might take a while.',
	    __("A + $lcopath/A/deep.new"),
	    __("U   $lcopath/A/deep.new/foo"),
	    __("A + $lcopath/A/deep.new/bar"),
	    __("U   $lcopath/A/normal"),
	    __("A + $lcopath/A/foo.new"),
	    __("D   $lcopath/A/bar"),
	    __("C   $lcopath/A/deep"),
	    __("D   $lcopath/A/deep/foo"),
	    __("C   $lcopath/A/deep/test.pl"),
	    __("D   $lcopath/A/foo"),
	    __("U   $lcopath/test.pl")." - A/deep/test.pl",
	    "New merge ticket: $uuid:/trunk:8",
	    '2 conflicts found.']);
