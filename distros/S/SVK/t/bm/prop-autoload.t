#!/usr/bin/perl -w
use strict;
use SVK::Test;
plan tests => 4;
our $output;

my ($xd, $svk) = build_test('test','rootProject');

$svk->mkdir(-m => 'trunk', '/test/trunk');
$svk->mkdir(-m => 'trunk', '/test/branches');
$svk->mkdir(-m => 'trunk', '/test/tags');
my $tree = create_basic_tree($xd, '/test/trunk');

my $depot = $xd->find_depot('test');
my $uri = uri($depot->repospath);

my ($copath, $corpath) = get_copath('bm-prop-autoload');

my $props = { 
    'svk:project:projectA:path-trunk' => '/trunk',
    'svk:project:projectA:path-branches' => '/branches',
    'svk:project:projectA:path-tags' => '/tags',
};

add_prop_to_basic_tree($xd, '/test/',$props);
$svk->mirror('//mirror/MyProject', $uri);
$svk->sync('//mirror/MyProject');

is_output ($svk, 'propget',
    ['svk:project:projectA:path-trunk', '//mirror/MyProject'],
    [$props->{'svk:project:projectA:path-trunk'}]);

$svk->cp(-m => 'branch Foo', '//mirror/MyProject/trunk', '//mirror/MyProject/branches/Foo');

$svk->mirror('--detach', '//mirror/MyProject');

$svk->mirror('/rootProject/', $uri);
$svk->sync('/rootProject/');
is_output ($svk, 'propget',
    ['svk:project:projectA:path-trunk', '/rootProject/'],
    [$props->{'svk:project:projectA:path-trunk'}]);

is_output ($svk, 'branch', ['--list','/rootProject/'], ['Foo']);
$svk->checkout('/rootProject/',$copath);

chdir($copath);
is_output ($svk, 'branch', ['--list'], ['Foo']);
