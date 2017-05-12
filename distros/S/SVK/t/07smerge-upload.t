#!/usr/bin/perl -w
use strict;
use SVK::Test;
plan tests => 1;

our $output;
# build another tree to be mirrored ourself
my ($xd, $svk) = build_test('new');

$svk->mkdir ('-m', 'this is the local tree', '//local');
my $tree = create_basic_tree ($xd, '//local');
waste_rev ($svk, '/new/void') for 1..10;
$svk->mkdir ('-m', 'this is the new remote trunk', '/new/trunk');
my ($srepospath, $spath, $srepos) = $xd->find_repos ('/new/trunk', 1);
my $uri = uri($srepospath);
$svk->mirror ('//trunk', $uri.($spath eq '/' ? '' : $spath));
$svk->sync ('//trunk');

$svk->smerge ('-IB', '//local', '//trunk');
is ($srepos->fs->youngest_rev, 23);
