#!/usr/bin/perl -w
use strict;
use SVK::Test;
plan tests => 1;
our $output;

my ($xd, $svk) = build_test('test', 'client2');
my ($copath, $corpath) = get_copath ('commit-multi');

my $tree = create_basic_tree ($xd, '/test/');
my ($srepospath, $spath, $srepos) = $xd->find_repos ('/test/A', 1);
my $uri = uri($srepospath);

$svk->mirror ('/client2/remote', $uri);
$svk->mirror ('//A', "$uri/A");

$svk->sync ('-a');
mkdir ($copath);
$svk->checkout ('//A', "$copath/A");
$svk->checkout ('/client2/remote', "$copath/full");

append_file ("$copath/A/be", "foobar\n");
$svk->commit ('-m', 'modify A', "$copath/A");
append_file ("$copath/full/B/fe", "foobar\n");
$svk->commit ('-m', 'modify A', "$copath/full/B");
is_output ($svk, 'st', ["$copath/full"], []);
