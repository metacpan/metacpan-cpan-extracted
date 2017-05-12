#!/usr/bin/perl -w
use strict;
use SVK::Test;
plan tests => 4;
our $output;

my ($xd, $svk) = build_test('test');

$svk->mkdir('-p', -m => 'trunk in project B', '/test/projectB/trunk');
$svk->mkdir(-m => 'branches in project B', '/test/projectB/branches');
$svk->mkdir(-m => 'tags in project B', '/test/projectB/tags');
my $tree = create_basic_tree($xd, '/test/projectB/trunk');

my $depot = $xd->find_depot('test');
my $uri = uri($depot->repospath);

my ($copath, $corpath) = get_copath('tag-from-wc');

$svk->mirror('//mirror/nomeans', $uri);
$svk->sync('//mirror/nomeans');

$svk->checkout('//mirror/nomeans/projectB/trunk',$copath);

chdir($copath);

$answer = ['','','',''];
is_output_like ($svk, 'branch', ['--setup', '//mirror/nomeans/projectB'],
    qr/Project detected in specified path./);

$svk->br('--create','Foo','--switch-to', '--project','projectB');
is_output_like ($svk, 'branch', [],
    qr/Branch: Foo .online./);

# for http://task.hm/GN5C
$svk->br('--create','Bar','--tag','--from','Foo');
is_output ($svk, 'branch', ['--list', '--tag'],
    ['Bar']);

$svk->br('--create','Bar2','--tag','--from','.');
is_output ($svk, 'branch', ['--list', '--tag'],
    ['Bar','Bar2']);
