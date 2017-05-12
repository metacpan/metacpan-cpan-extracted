#!/usr/bin/perl -w
use strict;
use Test::More;
use SVK::Test;
eval { require SVN::Mirror; 1 } or plan skip_all => 'require SVN::Mirror';
plan tests => 4;

my ($xd, $svk) = build_test('test');

our $output;

$svk->mkdir(-pm => 'init', '/test/foo/bar/proj/trunk');
$svk->mkdir(-pm => 'init', '/test/foo/bar/proj/branches');
my $tree = create_basic_tree ($xd, '/test/foo/bar/proj/trunk');

$svk->cp('-m' => 'branch', '/test/foo/bar/proj/trunk' => '/test/foo/bar/proj/branches/branchA');

my ($copath, $corpath) = get_copath();

$svk->mv(-m => 'move it', '/test/foo' => '/test/blah');

$svk->cp(-m => 'branch2', '/test/blah/bar/proj/trunk' => '/test/blah/bar/proj/branches/branchB');

$svk->mv(-m => 'move it', '/test/blah/bar/proj' => '/test/proj');

$svk->cp(-m => 'branch3', '/test/proj/trunk' => '/test/proj/branches/branchC');

my ($srepospath, $spath, $srepos) = $xd->find_repos ('/test/proj', 1);
my $uri = uri($srepospath.($spath eq '/' ? '' : $spath));


$svk->mi('//mirror/proj', $uri);

is_output($svk, 'sync', ['--follow-anchor-copy','//mirror/proj'],
          ["Syncing $uri",
           'Retrieving log information from 1 to 9',
           'Retrieving log information from 1 to 8',
           'Committed revision 2 from revision 1.',
           'Committed revision 3 from revision 2.',
           'Committed revision 4 from revision 3.',
           'Committed revision 5 from revision 4.',
           'Committed revision 6 from revision 5.',
           'Committed revision 7 from revision 7.',
           'Committed revision 8 from revision 9.']);

is_ancestor($svk, "//mirror/proj/branches/branchA", '/mirror/proj/trunk', 5);
is_ancestor($svk, "//mirror/proj/branches/branchB", '/mirror/proj/trunk', 5);
is_ancestor($svk, "//mirror/proj/branches/branchC", '/mirror/proj/trunk', 5);

