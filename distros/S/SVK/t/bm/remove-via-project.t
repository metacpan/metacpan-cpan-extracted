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

my ($copath, $corpath) = get_copath('remove-via-project');

$svk->mirror('//mirror/nomeans', $uri);
$svk->sync('//mirror/nomeans');

$svk->checkout('//mirror/nomeans/projectB/trunk',$copath);

chdir($copath);

$answer = ['','','',''];
is_output_like ($svk, 'branch', ['--setup', '//mirror/nomeans/projectB'],
    qr/Project detected in specified path./);

$svk->br('--create','Foo','--project','projectB');
$svk->br('--create','Bar','--project','projectB');
is_output ($svk, 'branch', ['--list', '--project', 'projectB'],
    ['Bar','Foo'],
    '"br --list --project projectB" after create branches Foo and Bar');
$svk->br('--remove','Foo','--project','projectB');
is_output ($svk, 'branch', ['--list', '--project', 'projectB'],
    ['Bar'],
    '"br --list --project projectB" after remove Foo');
chdir('..'); # so not in a wc anymore
# for http://task.hm/GVQ3
$svk->br('--remove','Bar','--project','projectB');
is_output ($svk, 'branch', ['--list', '--project', 'projectB'],
    [],
    '"br --list --project projectB" after chdir to non-wc and remove Bar');
