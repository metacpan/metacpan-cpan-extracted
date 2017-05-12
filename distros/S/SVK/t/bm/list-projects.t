#!/usr/bin/perl -w
use strict;
use SVK::Test;
plan tests => 2;
our $output;

my ($xd, $svk) = build_test('test');

$svk->mkdir('-p', -m => 'trunk in project B', '/test/projectB/trunk');
$svk->mkdir(-m => 'branches in project B', '/test/projectB/branches');
$svk->mkdir(-m => 'tags in project B', '/test/projectB/tags');
my $tree = create_basic_tree($xd, '/test/');
$tree = create_basic_tree($xd, '/test/projectB/trunk');

my $depot = $xd->find_depot('test');
my $uri = uri($depot->repospath);

my ($copath, $corpath) = get_copath('list-projects');

$svk->mirror('//mirror/nomeans', $uri);
$svk->sync('//mirror/nomeans');

$answer = ['','','',''];
is_output_like ($svk, 'branch', ['--setup', '//mirror/nomeans/projectB'],
    qr/Project detected in specified path./);
is_output ($svk, 'branch', ['--list-projects'],
    ['projectB (depot: )']);
