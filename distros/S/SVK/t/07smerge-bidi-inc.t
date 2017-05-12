#!/usr/bin/perl -w
use strict;
use Test::More;
use Cwd;
use File::Path;

use SVK::Test;
plan tests => 7;

# These tests actually use push and pull, in the hope that I'll get less
# confused. This should be okay, because other tests demonstrate that
# push/pull function the same as smerge. 

my $initial_cwd = getcwd;

# build another tree to be mirrored ourself
my ($xd, $svk) = build_test('test');

my $tree = create_basic_tree ($xd, '/test/');

my ($copath_test, $corpath_test) = get_copath ('bidi-inc-test');
my ($copath_default, $corpath_default) = get_copath ('bidi-inc-default');
my ($copath_second, $corpath_second) = get_copath ('bidi-inc-second');

my ($test_repospath, $test_a_path, $test_repos) =$xd->find_repos ('/test/A', 1);
my $test_uuid = $test_repos->fs->get_uuid;

my ($default_repospath, $default_path, $default_repos) =$xd->find_repos ('//A', 1);
my $default_uuid = $default_repos->fs->get_uuid;

my $uri = uri($test_repospath);
$svk->mirror ('//m', $uri.($test_a_path eq '/' ? '' : $test_a_path));

$svk->sync ('//m');

$svk->copy ('-m', 'branch', '//m', '//l');
$svk->checkout ('//l', $corpath_default);

ok (-e "$corpath_default/be");
append_file ("$corpath_default/be", "from local branch\n");
mkdir "$corpath_default/T/";
append_file ("$corpath_default/T/xd", "local new file\n");

$svk->add ("$corpath_default/T");
$svk->delete ("$corpath_default/Q/qu");

$svk->commit ('-m', 'local modification from branch', "$corpath_default");

append_file ("$corpath_default/T/xd", "more content\n");
$svk->commit ('-m', 'second local modification from branch', "$corpath_default");

chdir ($corpath_default);
is_output ($svk, "push", [], [
        "Auto-merging (0, 6) /l to /m (base /m:3).",
        "===> Auto-merging (0, 4) /l to /m (base /m:3).",
        "Merging back to mirror source $uri/A.",
        "Empty merge.",
        "===> Auto-merging (4, 5) /l to /m (base /m:3).",
        "Merging back to mirror source $uri/A.",
        "D   Q/qu",
        "A   T",
        "A   T/xd",
        "U   be",
        "New merge ticket: $default_uuid:/l:5",
        "Merge back committed as revision 3.",
        "Syncing $uri/A",
        "Retrieving log information from 3 to 3",
        "Committed revision 7 from revision 3.",
        "===> Auto-merging (5, 6) /l to /m (base /l:5).",
        "Merging back to mirror source $uri/A.",
        "U   T/xd",
        "New merge ticket: $default_uuid:/l:6",
        "Merge back committed as revision 4.",
        "Syncing $uri/A",
        "Retrieving log information from 4 to 4",
        "Committed revision 8 from revision 4."]);

append_file ("$corpath_default/T/xd", "even more content\n");
$svk->commit ('-m', 'third local modification from branch', "$corpath_default");

append_file ("$corpath_default/be", "more content\n");
$svk->commit ('-m', 'fourth local modification from branch', "$corpath_default");

is_output ($svk, 'push', ['-l'], [
        "Auto-merging (6, 10) /l to /m (base /l:6).",
        "Merging back to mirror source $uri/A.",
        "U   T/xd",
        "U   be",
        "New merge ticket: $default_uuid:/l:10",
        "Merge back committed as revision 5.",
        "Syncing $uri/A",
        "Retrieving log information from 5 to 5",
        "Committed revision 11 from revision 5."]);


$svk->checkout ('/test/A', $corpath_test);

# add a file to remote
append_file ("$corpath_test/new-file", "some text\n");
$svk->add ("$corpath_test/new-file");

$svk->commit ('-m', 'making changes in remote depot', "$corpath_test");

chdir ($corpath_default);
append_file ("$corpath_default/be", "yet more content\n");
$svk->commit ('-m', 'simultaneous local modification from branch', "$corpath_default");

chdir ($corpath_test);
append_file ("$corpath_test/new-file", "some extra text\n");
$svk->commit ('-m', 'more changes in remote depot', "$corpath_test");
chdir ($corpath_default);

# server should be less strict
is_output ($svk, 'push', [], [
        "Auto-merging (10, 12) /l to /m (base /l:10).",
        "===> Auto-merging (10, 12) /l to /m (base /l:10).",
        "Merging back to mirror source $uri/A.",
	qr"Transaction is out of date: .+ '/A' .+",
	 'Please sync mirrored path /m first.']);

$svk->sync('//m');

is_output ($svk, 'push', [], [
        "Auto-merging (10, 12) /l to /m (base /l:10).",
        "===> Auto-merging (10, 12) /l to /m (base /l:10).",
        "Merging back to mirror source $uri/A.",
        "U   be",
        "New merge ticket: $default_uuid:/l:12",
        "Merge back committed as revision 8.",
        "Syncing $uri/A",
        "Retrieving log information from 8 to 8",
        "Committed revision 15 from revision 8."]);

append_file ("$corpath_default/be", "and more content\n");
$svk->commit ('-m', 'additional local modification from branch', "$corpath_default");

is_output ($svk, 'push', [], [
        "Auto-merging (12, 16) /l to /m (base /l:12).",
        "===> Auto-merging (12, 16) /l to /m (base /l:12).",
        "Merging back to mirror source $uri/A.",
        "U   be",
        "New merge ticket: $default_uuid:/l:16",
        "Merge back committed as revision 9.",
        "Syncing $uri/A",
        "Retrieving log information from 9 to 9",
        "Committed revision 17 from revision 9."]);

is_output ($svk, "pull", ['--force-incremental'],
      [ "Syncing $uri/A",
	'Auto-merging (3, 17) /m to /l (base /l:16).',
	'===> Auto-merging (3, 7) /m to /l (base /l:5).',
	'Empty merge.',
	'===> Auto-merging (7, 8) /m to /l (base /l:6).',
	'Empty merge.',
	'===> Auto-merging (8, 11) /m to /l (base /l:10).',
	'Empty merge.',
	'===> Auto-merging (11, 13) /m to /l (base /l:10).',
        "A   new-file",
        "New merge ticket: $test_uuid:/A:6",
        "Committed revision 18.",
        "===> Auto-merging (13, 14) /m to /l (base /m:13).",
        "U   new-file",
        "New merge ticket: $test_uuid:/A:7",
        "Committed revision 19.",
	"===> Auto-merging (14, 15) /m to /l (base */m:14).",
	"Empty merge.",
	"===> Auto-merging (15, 17) /m to /l (base */m:15).",
	"Empty merge.",
        "Syncing //l(/l) in $corpath_default to 19.",
        "A   new-file"]);
