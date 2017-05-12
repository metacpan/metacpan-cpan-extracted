#!/usr/bin/perl -w
use strict;
use Test::More;
use SVK::Test;
eval { require SVN::Mirror; 1 } or plan skip_all => 'require SVN::Mirror';
plan tests => 5;

my ($xd, $svk) = build_test('test');

our $output;

$svk->mkdir(-pm => 'init', '/test/foo/proj/trunk');
$svk->mkdir(-pm => 'init', '/test/foo/proj/branches');
my $tree = create_basic_tree ($xd, '/test/foo/proj/trunk');

$svk->cp('-m' => 'branch', '/test/foo/proj/trunk' => '/test/foo/proj/branches/branchA');

my ($copath, $corpath) = get_copath ('sync-rebase-delta');

$svk->checkout ('/test/', $copath);
$svk->mv("$copath/foo/proj" => "$copath/proj");
$svk->mkdir("$copath/proj/lalala");
# XXX: after the commit there are stalled sticky entries in checkout
# DH, please check.
is_output($svk, 'ci', [-m => 'mv but with some modification', $copath],
          [ "Committed revision 6." ]);

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
           'Committed revision 7 from revision 6.',
           'Committed revision 8 from revision 7.']);

is_output($svk, 'ls', ['//mirror/proj'],
          ['branches/', 'lalala/', 'trunk/'] );
is_ancestor($svk, "//mirror/proj/branches/branchA", '/mirror/proj/trunk', 5);
is_ancestor($svk, "//mirror/proj/branches/branchB", '/mirror/proj/trunk', 5);

