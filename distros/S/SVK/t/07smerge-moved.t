#!/usr/bin/perl -w
use Test::More tests => 1;
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

mkdir "$copath/";
mkdir "$copath/deep";
overwrite_file ("$copath/foo", "foobar\n");
$svk->add ("$copath/foo", "$copath/deep");
$svk->commit ('-m', 'init', "$copath");

$svk->cp ('-m', 'branch', '//trunk', '//local');

$svk->mv ('-m', 'move foo', '//trunk/foo', '//trunk/deep/foo');

($copath, $corpath) = get_copath();
$svk->checkout ('//local', $copath);

is_output ($svk, 'smerge', ['//trunk', $copath],
	   ['Auto-merging (2, 4) /trunk to /local (base /trunk:2).',
	    __("A + $copath/deep/foo"),
	    __("D   $copath/foo"),
	    "New merge ticket: $uuid:/trunk:4"]);
