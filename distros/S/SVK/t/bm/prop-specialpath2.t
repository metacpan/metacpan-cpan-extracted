#!/usr/bin/perl -w
# This test for trunk and branches placed in the same directory
use strict;
use SVK::Test;
plan tests => 5;
our $output;

my ($xd, $svk) = build_test('test');

$svk->mkdir(-m => 'trunk', '-p', '/test/branches/3.8-TESTING');
my $tree = create_basic_tree($xd, '/test/branches/3.8-TESTING');

my $depot = $xd->find_depot('test');
my $uri = uri($depot->repospath);

my ($copath, $corpath) = get_copath('trunk-branches-same-dir');

my $props = { 
    'svk:project:rt38:path-trunk' => '/branches/3.8-TESTING',
    'svk:project:rt38:path-branches' => '/branches',
    'svk:project:rt38:path-tags' => '/tags',
};

add_prop_to_basic_tree($xd, '/test/',$props);
$svk->mirror('//mirror/MyProject', $uri);
$svk->sync('//mirror/MyProject');
$svk->checkout('//mirror/MyProject',$copath);

chdir($copath);
is_output ($svk, 'propget',
    ['svk:project:rt38:path-trunk', ''],
    [$props->{'svk:project:rt38:path-trunk'}]);

is_output_like ($svk, 'branch', ['--create', 'foo'], qr'Project branch created: foo');
#TODO: {
#local $TODO = "should create from branches/3.8-TESTING and 3.8-TESTING is not one of branches";
is_output ($svk, 'branch', ['--list'], ['foo']);
is_output ($svk, 'list', ['//mirror/MyProject/branches/foo'],
    ['A/' , 'B/', 'C/', 'D/', 'me']);
$svk->branch ('--remove', 'foo');
is_output ($svk, 'branch', ['--list'], []);
#}
