#!/usr/bin/perl -w
use strict;
use SVK::Test;
plan tests => 5;

our ($output, $answer);
# build another tree to which we want to mirror ourselves.
my ($xd, $svk) = build_test('svm-empty', 'real-empty');
my ($copath, $corpath) = get_copath ('svm-empty');

$svk->mkdir ('-m', 'remote trunk', '/svm-empty/trunk');
$svk->ps ('-m', 'foo', 'bar' => 'baz', '/svm-empty/trunk');
$svk->mkdir ('-m', 'this is the local tree', '//local');
waste_rev ($svk, '//local/tree');

my ($drepospath, $dpath, $drepos) = $xd->find_repos ('/svm-empty/trunk', 1);
my $uri = uri($drepospath);
$svk->mirror ('//remote', $uri.($dpath eq '/' ? '' : $dpath));

is_output($svk, 'sync', ['//remote'],
	  ["Syncing $uri/trunk",
	   'Retrieving log information from 1 to 2',
	   'Committed revision 5 from revision 1.',
	   'Committed revision 6 from revision 2.']);
my ($srepospath, $spath, $srepos) = $xd->find_repos ('//remote', 1);
my $old_srev = $srepos->fs->youngest_rev;
$svk->sync ('//remote');
$svk->sync ('//remote');
$svk->sync ('//remote');
is ($srepos->fs->youngest_rev, $old_srev, 'sync is idempotent');

$svk->smerge ('-IB', '//local', '//remote');
$svk->smerge ('-IB', '//local', '//remote');
is ($drepos->fs->youngest_rev, 4, 'smerge -IB is idempotent');

my ($repospath, $path, $repos) = $xd->find_repos ('/real-empty/', 1);
$uri = uri($repospath);
my $uuid = $srepos->fs->get_uuid;
$answer = ['', 'empty', ''];
$svk->cp (-m => 'branch empty repository', $uri, '//test');

$svk->co ('//test', $copath);
chdir ($copath);
is_output ($svk, 'push', [],
	   ["Auto-merging (0, 10) /test to /mirror/empty (base /:0).",
	    "===> Auto-merging (0, 10) /test to /mirror/empty (base /:0).",
	    "Merging back to mirror source $uri.",
	    'Empty merge.']);
$svk->mkdir ('-m', 'Added trunk', '//test/trunk');
is_output ($svk, 'push', [],
          ["Auto-merging (0, 11) /test to /mirror/empty (base /:0).",
	   "===> Auto-merging (0, 10) /test to /mirror/empty (base /:0).",
	   "Merging back to mirror source $uri.",
	   "Empty merge.",
	   "===> Auto-merging (10, 11) /test to /mirror/empty (base /:0).",
	   "Merging back to mirror source $uri.",
	   "A   trunk",
	   "New merge ticket: $uuid:/test:11",
	   "Merge back committed as revision 1.",
	   "Syncing $uri",
	   "Retrieving log information from 1 to 1",
	   "Committed revision 12 from revision 1."]);
