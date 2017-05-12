#!/usr/bin/perl -w
# This test for loading project from multiprojects via props
use strict;
use SVK::Test;
plan tests => 11;
our $output;

my ($xd, $svk) = build_test('test');

$svk->mkdir(-m => 'trunk of project A', '-p', '/test/trunk/projA');
$svk->mkdir(-m => 'trunk of project B', '/test/trunk/projB');
my $tree = create_basic_tree($xd, '/test/trunk/projA');
$tree = create_basic_tree($xd, '/test/trunk/projB');

my $depot = $xd->find_depot('test');
my $uri = uri($depot->repospath);

my ($copath, $corpath) = get_copath('multi-A');
my ($copathB, $corpathB) = get_copath('multi-B');

my $props = { 
    'svk:project:projectA:path-trunk' => '/trunk/projA',
    'svk:project:projectA:path-branches' => '/branches/A',
    'svk:project:projectA:path-tags' => '/tags/A',
    'svk:project:projectB:path-trunk' => '/trunk/projB',
    'svk:project:projectB:path-branches' => '/branches/B',
    'svk:project:projectB:path-tags' => '/tags/B',
};

add_prop_to_basic_tree($xd, '/test/',$props);
$svk->mirror('//mirror/projectA', $uri);
$svk->sync('//mirror/projectA');

is_output ($svk, 'propget',
    ['svk:project:projectA:path-trunk', '//mirror/projectA'],
    [$props->{'svk:project:projectA:path-trunk'}]);

$svk->checkout('//mirror/projectA',$copath);

chdir($copath);
is_output ($svk, 'propget',
    ['svk:project:projectA:path-trunk', ''],
    [$props->{'svk:project:projectA:path-trunk'}]);

is_output_like ($svk, 'branch', ['--create', 'foo'], qr'Project branch created: foo');
is_output ($svk, 'branch', ['--list'], ['foo']);
#TODO: {
#local $TODO = "should create from  /trunk/proj instead /trunk";
is_output ($svk, 'list', ['//mirror/projectA/branches/A/foo'],
    ['A/' , 'B/', 'C/', 'D/', 'me']);
#}

is_output ($svk, 'mirror', ['//mirror/projectB', $uri],
    ["Mirroring overlapping paths not supported"]);

$svk->mirror('-d', '//mirror/projectA');
$svk->mirror('//mirror/projectB', $uri);
$svk->sync('//mirror/projectB');

is_output ($svk, 'propget',
    ['svk:project:projectB:path-trunk', '//mirror/projectB'],
    [$props->{'svk:project:projectB:path-trunk'}]);

chdir('../../../');
$svk->checkout('//mirror/projectB',$copathB);

chdir($copathB.'/trunk/projB');

is_output_like ($svk, 'branch', [], qr'Project name: projectB');
is_output_like ($svk, 'branch', ['--create', 'bar'], qr'Project branch created: bar');
is_output ($svk, 'branch', ['--list'], ['bar']);
#TODO: {
#local $TODO = "should create from /trunk/proj and put into branches/B";
is_output ($svk, 'list', ['//mirror/projectB/branches/B/bar'],
    ['A/' , 'B/', 'C/', 'D/', 'me']);
#}
