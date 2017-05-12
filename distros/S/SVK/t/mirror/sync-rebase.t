#!/usr/bin/perl -w
use strict;
use Test::More;
use SVK::Test;
eval { require SVN::Mirror; 1 } or plan skip_all => 'require SVN::Mirror';
plan tests => 3;

my ($xd, $svk) = build_test('test');

our $output;

$svk->mkdir(-pm => 'init', '/test/foo/proj/trunk');
$svk->mkdir(-pm => 'init', '/test/foo/proj/branches');
my $tree = create_basic_tree ($xd, '/test/foo/proj/trunk');

$svk->cp('-m' => 'branch', '/test/foo/proj/trunk' => '/test/foo/proj/branches/branchA');

$svk->mv(-m => 'relocate proj base', '/test/foo/proj' => '/test/proj');

$svk->cp(-m => 'branch2', '/test/proj/trunk' => '/test/proj/branches/branchB');

my ($srepospath, $spath, $srepos) = $xd->find_repos ('/test/proj', 1);
my $uri = uri($srepospath.($spath eq '/' ? '' : $spath));


$svk->mi('//mirror/proj', $uri);

is_output($svk, 'sync', ['--follow-anchor-copy','//mirror/proj'],
          ["Syncing $uri",
           'Retrieving log information from 1 to 7',
           'Retrieving log information from 1 to 6',
           'Committed revision 2 from revision 1.',
           'Committed revision 3 from revision 2.',
           'Committed revision 4 from revision 3.',
           'Committed revision 5 from revision 4.',
           'Committed revision 6 from revision 5.',
           'Committed revision 7 from revision 7.']);


is_ancestor($svk, "//mirror/proj/branches/branchA", '/mirror/proj/trunk', 5);
is_ancestor($svk, "//mirror/proj/branches/branchB", '/mirror/proj/trunk', 5);

