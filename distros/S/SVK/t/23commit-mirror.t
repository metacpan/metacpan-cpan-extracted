#!/usr/bin/perl -w
use strict;
use SVK::Test;
plan tests => 8;

my ($xd, $svk) = build_test('test');

my $tree = create_basic_tree ($xd, '/test/');
my ($srepospath, $spath, $srepos) = $xd->find_repos ('/test/', 1);

my $uri = uri($srepospath);

$svk->mirror ('//remote', $uri);
$svk->sync ('//remote');
$svk->cp ('-m', 'local', '//remote', '//local');
my ($copath, $corpath) = get_copath ('commit-opt');
$svk->checkout ('//', $copath);
append_file ("$copath/local/A/be", "modified on A\n");
append_file ("$copath/remote/A/be", "modified on A\n");
is_output ($svk, 'commit', ['-m', 'modify A', $copath],
	   [__("$copath/remote is a mirrored path, please commit separately."),
	    'Committed revision 5.']);
is_output ($svk, 'status', [$copath],
	   [__"M   $copath/remote/A/be"]);

is_output ($svk, 'commit', ['-P', 'mirror-test', '-m', 'modify A', "$copath/remote"],
	   ["Patching locally against mirror source $uri.",
		 'Patch mirror-test created.']);

is_output ($svk, 'commit', ['-m', 'modify A', "$copath/remote"],
	   [map qr'.*',(1..5),
	    'Committed revision 6 from revision 3.']);

is_output ($svk, 'commit', ['-m', 'empty', $copath],
	   ['No targets to commit.']);

# XXX: maybe don't report unless we have something to commit in mpath.
append_file ("$copath/local/A/be", "modified on A\n");
is_output ($svk, 'commit', ['-m', 'modify A', $copath],
	   [__("$copath/remote is a mirrored path, please commit separately."),
	    'Committed revision 7.']);

append_file ("$copath/remote/A/direct-file", "modified on A\n");
$svk->add ("$copath/remote/A/direct-file");
$svk->up(-r6 => "$copath/local/A/be");
is_output($svk, 'ci', [-m => 'commit from mixed-revision checkout', "$copath/remote"],
	  ['Commit into mirrored path: merging back directly.',
	   "Merging back to mirror source $uri.",
	   'Merge back committed as revision 4.',
	   "Syncing $uri",
	   'Retrieving log information from 4 to 4',
	   'Committed revision 8 from revision 4.']);

append_file ("$copath/remote/A/direct-file", "more modification on A\n");
# this ruins the mirror state
is_output ($svk, 'commit', ['--direct', '-m', 'modify A directly', "$copath/remote"],
	   ['Committed revision 9.']);
