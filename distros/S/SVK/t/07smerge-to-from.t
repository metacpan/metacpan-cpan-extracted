#!/usr/bin/perl -w
use Test::More tests => 7;
use strict;
use File::Path;
use Cwd;
use SVK::Test;

my ($xd, $svk) = build_test();
my ($copath, $corpath) = get_copath();

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

$svk->mkdir ('-m', 'mkdir random', '//random');

is_output ($svk, 'smerge', ['-m', 'merging to local', '--to', '//local'],
                ["Auto-merging (2, 4) /trunk to /local (base /trunk:2).",
                 "D   A",
                 "New merge ticket: $uuid:/trunk:4",
                 "Committed revision 6."]);

$svk->rm ('-m', 'rm B on local', '//local/B');

is_output ($svk, 'smerge', ['-m', 'merging from local', '--from', '//local'], 
                ["Auto-merging (0, 7) /local to /trunk (base /trunk:4).",
                 "D   B",
                 "New merge ticket: $uuid:/local:7",
                 "Committed revision 8."]);

$svk->rm ('-m', 'rm B on local', '//local/test.pl');
$svk->switch ('//local', $copath);

is_output ($svk, 'smerge', ['-m', 'merging from copath', '--from', $copath],
                ["Auto-merging (7, 9) /local to /trunk (base /local:7).",
                 "D   test.pl",
                 "New merge ticket: $uuid:/local:9",
                 "Committed revision 10."]);

is_output ($svk, 'smerge', ['-m', 'failed merge', '--from', '--to', '//local'],
                ["Cannot specify both 'to' and 'from'."]);

is_output ($svk, 'smerge', ['-m', 'failed merge', '--from', '//local', '//remote'],
                ["Cannot specify 'to' or 'from' when specifying a source and destination."]);

is_output_like ($svk, 'smerge', [], qr/SYNOPSIS/);

is_output ($svk, 'smerge', ['-m', 'failed merge', '--from', '//random'],
                ["Cannot find the path which '//random' copied from."]);
