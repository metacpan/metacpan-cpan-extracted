#!/usr/bin/perl -w
use strict;
use SVK::Test;
plan tests => 3;
our $output;

my ($xd, $svk) = build_test('test');

$svk->mkdir('-p', -m => 'trunk in project A', '/test/projectA/trunk');
$svk->mkdir(-m => 'branches in project A', '/test/projectA/branches');
$svk->mkdir(-m => 'tags in project A', '/test/projectA/tags');
$svk->mkdir('-p', -m => 'trunk in project B', '/test/projectB/trunk');
$svk->mkdir(-m => 'branches in project B', '/test/projectB/branches');
$svk->mkdir(-m => 'tags in project B', '/test/projectB/tags');
my $tree = create_basic_tree($xd, '/test/projectA/trunk');

my $depot = $xd->find_depot('test');
my $uri = uri($depot->repospath);

$svk->mirror('//mirror/twoProject', $uri);
$svk->sync('//mirror/twoProject');

$svk->cp(-m => 'branch Foo in projectA', '//mirror/twoProject/projectA/trunk',
    '//mirror/twoProject/projectA/branches/Foo');

$svk->cp(-m => 'branch Bar in projectB', '//mirror/twoProject/projectB/trunk',
    '//mirror/twoProject/projectB/branches/Bar');

my ($copath, $corpath) = get_copath('prop-multiproject');

# set prop for project A
my $proppath = { 'trunk' => '/mirror/twoProject/projectA/trunk', 
    'branches' => '/mirror/twoProject/projectA/branches',
    'tags' => '/mirror/twoProject/projectA/tags',
    'hooks' => '/mirror/twoProject/projectA/hooks',
};

$svk->propset('-m', "- projectA trunk path set", 'svk:project:projectA:path-trunk',
    $proppath->{trunk}, "//"); 
$svk->propset('-m', "- projectA branches path set", 'svk:project:projectA:path-branches',
    $proppath->{branches}, "//");
$svk->propset('-m', "- projectA tags path set", 'svk:project:projectA:path-tags',
    $proppath->{tags}, "//");
is_output ($svk, 'propget', ['svk:project:projectA:path-trunk', '//'], [$proppath->{trunk}]);

$svk->checkout('//mirror/twoProject/projectB', $copath); # checkout project B

chdir($copath);

# in checkout of project B, list
is_output ($svk, 'branch', ['--list'], ['Bar']);

# try to list project branches via mirrored path
is_output ($svk, 'branch', ['--list','//mirror/twoProject/projectA'], ['Foo']);

