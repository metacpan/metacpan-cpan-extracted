#!/usr/bin/perl -w
use Test::More tests => 2;
use strict;
use File::Path;
use Cwd;
use SVK::Test;

my ($xd, $svk) = build_test();
our $output;
my ($copath, $corpath) = get_copath ('smerge-moved-dest');
$svk->mkdir ('-m', 'trunk', '//trunk');
$svk->checkout ('//trunk', $copath);
my ($repospath, undef, $repos) = $xd->find_repos ('//', 1);
my $uuid = $repos->fs->get_uuid;

mkdir "$copath/A";
mkdir "$copath/A/deep";
overwrite_file("$copath/A/foo", "foobar\n");
overwrite_file("$copath/A/deep/foo", "foobar\n");

$svk->add("$copath/A");
$svk->commit ('-m', 'init', "$copath");
$svk->cp('-m', 'branch', '//trunk', '//local');

overwrite_file("$copath/A/foo", "foobar changed\n");
overwrite_file("$copath/A/deep/bar", "foobar\n");

$svk->add("$copath/A/deep/bar");
$svk->ci(-m => 'change on trunk', $copath);
$svk->mv('-m', 'move foo', '//local/A', '//local/A-away');
is_output($svk, 'sm', [-m => 'merge', '//trunk', '//local'],
	  ['Auto-merging (2, 4) /trunk to /local (base /trunk:2).',
	   '    A - skipped',
	   '    A/foo - skipped',
	   '    A/deep/bar - skipped',
	   'Empty merge.']);

is_output($svk, 'sm', ['--track-rename', -m => 'merge', '//trunk', '//local'],
	  ['Auto-merging (2, 4) /trunk to /local (base /trunk:2).',
	   'Collecting renames, this might take a while.',
	   'U   A/foo - A-away/foo',
	   'A   A/deep/bar - A-away/deep/bar',
	   qr'New merge ticket: .*:/trunk:4',
	   'Committed revision 6.']);

