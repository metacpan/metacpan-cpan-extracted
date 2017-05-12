#!/usr/bin/perl -w
use Test::More tests => 2;
use strict;
use SVK::Test;
our $output;
my ($xd, $svk) = build_test();
my ($copath, $corpath) = get_copath();
my ($repospath, undef, $repos) = $xd->find_repos ('//', 1);
$svk->checkout ('//', $copath);
chdir ($copath);
mkdir ('A');
overwrite_file ("A/foo", "foobar\nfnord\n");
overwrite_file ("A/bar", "foobar\n");
overwrite_file ("A/nor", "foobar\n");
$svk->add ('A');
$svk->commit ('-m', 'init');

append_file ("A/bar", "foobar\n");
$svk->commit ('-m', 'change bar');
$svk->up(-r1 => 'A/bar');
is_output($svk, 'st', [], []);
is_output($svk, 'diff', [], []);

