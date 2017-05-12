#!/usr/bin/perl -w
use Test::More tests => 1;
use strict;
use File::Path;
use Cwd;
use SVK::Test;

my ($xd, $svk) = build_test();
our $output;
our ($copath, $corpath) = get_copath();
$svk->mkdir ('-m', 'trunk', '//trunk');
$svk->checkout ('//trunk', $copath);
my ($repospath, undef, $repos) = $xd->find_repos ('//', 1);
my $uuid = $repos->fs->get_uuid;

mkdir "$copath/A";
$svk->add ("$copath/A");
$svk->commit ('-m', 'init', "$copath");

$svk->cp ('-m', 'branch', '//trunk', '//local');

$svk->rm ('-m', 'rm A on local', '//local/A');

append_file ("$copath/A/a_file", "add a file\n");
$svk->add ("$copath/A/a_file");
$svk->commit ('-m', 'add a file', "$copath");

mkdir "$copath/A/a_dir";
$svk->add ("$copath/A/a_dir");
$svk->commit ('-m', 'add a dir', "$copath");

# XXX: skipped is wrong, but anyway it must report things at least
is_output ($svk, 'smerge', ['-C', '//trunk', '//local'],
	   ['Auto-merging (2, 6) /trunk to /local (base /trunk:2).',
	    "    A - skipped",
	    "    A/a_file - skipped",
	    "    A/a_dir - skipped",
	    "Empty merge.",
	   ]);

