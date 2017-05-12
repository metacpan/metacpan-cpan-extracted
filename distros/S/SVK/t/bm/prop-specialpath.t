#!/usr/bin/perl -w
# This test for trunk and/or branches are not in trunk/ and/or branches/ directories
use strict;
use SVK::Test;
plan tests => 9;
our $output;

my ($xd, $svk) = build_test('test');

$svk->mkdir(-m => 'trunk', '-p', '/test/trunk/proj');
$svk->mkdir(-m => 'trunk', '/test/branches');
$svk->mkdir(-m => 'trunk', '/test/tags');
my $tree = create_basic_tree($xd, '/test/trunk/proj');

my $depot = $xd->find_depot('test');
my $uri = uri($depot->repospath);

my ($copath, $corpath) = get_copath('bm-prop-specialpath');

my $props = { 
    'svk:project:projectA:path-trunk' => '/trunk/proj',
    'svk:project:projectA:path-branches' => '/branches',
    'svk:project:projectA:path-tags' => '/tags',
};

add_prop_to_basic_tree($xd, '/test/',$props);
$svk->mirror('//mirror/MyProject', $uri);
$svk->sync('//mirror/MyProject');

is_output ($svk, 'propget',
    ['svk:project:projectA:path-trunk', '//mirror/MyProject'],
    [$props->{'svk:project:projectA:path-trunk'}]);

$svk->checkout('//mirror/MyProject',$copath);

chdir($copath);
is_output ($svk, 'propget',
    ['svk:project:projectA:path-trunk', ''],
    [$props->{'svk:project:projectA:path-trunk'}]);

is_output_like ($svk, 'branch', ['--create', 'foo'], qr'Project branch created: foo');
is_output ($svk, 'branch', ['--list'], ['foo']);
#TODO: {
#local $TODO = "should create from  /trunk/proj instead /trunk";
is_output ($svk, 'list', ['//mirror/MyProject/branches/foo'],
    ['A/' , 'B/', 'C/', 'D/', 'me']);
$svk->branch ('--remove', 'foo');
is_output ($svk, 'branch', ['--list'], []);
#}

$props->{'svk:project:projectA:path-branches'} = '/branches/projA';
add_prop_to_basic_tree($xd, '/test/',$props);

$svk->sync('//mirror/MyProject'); # sync properties

is_output_like ($svk, 'branch', ['--create', 'bar'], qr'Project branch created: bar');
is_output ($svk, 'branch', ['--list'], ['bar']);
#TODO: {
#local $TODO = "should create from /trunk/proj and put into branches/projA";
is_output ($svk, 'list', ['//mirror/MyProject/branches/projA/bar'],
    ['A/' , 'B/', 'C/', 'D/', 'me']);
#}
