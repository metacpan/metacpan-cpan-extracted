#!/usr/bin/perl -w
use strict;
use Test::More;
use Cwd;
use File::Path;

use SVK::Test;
plan tests => 10;

my $initial_cwd = getcwd;

# build another tree to be mirrored ourself
my ($xd, $svk) = build_test('test');

$svk->mkdir(-m => 'trunk','-p', '/test/A/trunk');
$svk->mkdir(-m => 'branches', '/test/A/branches');
$svk->mkdir(-m => 'tags', '/test/A/tags');

my $tree = create_basic_tree ($xd, '/test/A/trunk');

my ($copath_test, $corpath_test) = get_copath ('bm-push-pull-test');
my ($copath_default, $corpath_default) = get_copath ('bm-push-pull-default');
my ($copath_second, $corpath_second) = get_copath ('bm-push-pull-second');

my ($test_repospath, $test_a_path, $test_repos) =$xd->find_repos ('/test/A/trunk', 1);
my $test_uuid = $test_repos->fs->get_uuid;

my ($default_repospath, $default_path, $default_repos) =$xd->find_repos ('//A/trunk', 1);
my $default_uuid = $default_repos->fs->get_uuid;

my $uri = uri($test_repospath);
$svk->mirror ('//m', $uri);

$svk->sync ('//m');

$answer = ['', '','',''];
$svk->br('--setup', '//m/A',);

$svk->br('--create','lo2','--local','--project','A');

$svk->br('--checkout','--local','lo2', '--project','A',$corpath_default);

ok (-e "$corpath_default/A/be");
append_file ("$corpath_default/A/be", "from local branch\n");
mkdir "$corpath_default/A/T/";
append_file ("$corpath_default/A/T/xd", "local new file\n");

$svk->add ("$corpath_default/A/T");
$svk->delete ("$corpath_default/A/Q/qu");

$svk->commit ('-m', 'local modification from branch', "$corpath_default");

append_file ("$corpath_default/A/T/xd", "more content\n");
$svk->commit ('-m', 'second local modification from branch', "$corpath_default");

chdir ($corpath_default);
is_output ($svk, "branch", ['--push'], [
        "Auto-merging (0, 12) /local/A/lo2 to /m/A/trunk (base /m/A/trunk:6).",
        "===> Auto-merging (0, 10) /local/A/lo2 to /m/A/trunk (base /m/A/trunk:6).",
        "Merging back to mirror source $uri.",
        "Empty merge.",
        "===> Auto-merging (10, 11) /local/A/lo2 to /m/A/trunk (base /m/A/trunk:6).",
        "Merging back to mirror source $uri.",
        "D   A/Q/qu",
        "A   A/T",
        "A   A/T/xd",
        "U   A/be",
        "New merge ticket: $default_uuid:/local/A/lo2:11",
        "Merge back committed as revision 9.",
        "Syncing $uri",
        "Retrieving log information from 9 to 9",
        "Committed revision 13 from revision 9.",
        "===> Auto-merging (11, 12) /local/A/lo2 to /m/A/trunk (base /local/A/lo2:11).",
        "Merging back to mirror source $uri.",
        "U   A/T/xd",
        "New merge ticket: $default_uuid:/local/A/lo2:12",
        "Merge back committed as revision 10.",
        "Syncing $uri",
        "Retrieving log information from 10 to 10",
        "Committed revision 14 from revision 10."]);

append_file ("$corpath_default/A/T/xd", "even more content\n");
$svk->commit ('-m', 'third local modification from branch', "$corpath_default");

append_file ("$corpath_default/A/be", "more content\n");
$svk->commit ('-m', 'fourth local modification from branch', "$corpath_default");

is_output ($svk, 'branch', ['--push','--lump'], [
        "Auto-merging (12, 16) /local/A/lo2 to /m/A/trunk (base /local/A/lo2:12).",
        "Merging back to mirror source $uri.",
        "U   A/T/xd",
        "U   A/be",
        "New merge ticket: $default_uuid:/local/A/lo2:16",
        "Merge back committed as revision 11.",
        "Syncing $uri",
        "Retrieving log information from 11 to 11",
        "Committed revision 17 from revision 11."]);


#$svk->br('--checkout','trunk', $corpath_test);
$svk->checkout ('/test/A/trunk', $corpath_test);

# add a file to remote
append_file ("$corpath_test/A/new-file", "some text\n");
$svk->add ("$corpath_test/A/new-file");

$svk->commit ('-m', 'making changes in remote depot', "$corpath_test");

chdir ($corpath_default);
#is_output ($svk, "pull", [], [
is_output ($svk, "branch", ['--pull'], [
        "Syncing $uri",
        "Retrieving log information from 12 to 12",
        "Committed revision 18 from revision 12.",
	"Auto-merging (6, 18) /m/A/trunk to /local/A/lo2 (base /local/A/lo2:16).",
        "A   A/new-file",
        "New merge ticket: $test_uuid:/A/trunk:12",
        "Committed revision 19.",
        "Syncing //local/A/lo2(/local/A/lo2) in $corpath_default to 19.",
        __("A   A/new-file")]);

# add a file to remote
append_file ("$corpath_test/A/new-file", "some text\n");
$svk->add ("$corpath_test/A/new-file");

$svk->commit ('-m', 'making changes in remote depot', "$corpath_test");

chdir ($initial_cwd);

$svk->sync ("//m");

#is_output ($svk, "push", ['-C', "--from", "//m/A/trunk", "//local/A/lo2"], [
is_output ($svk, "branch", ['--push', '-C', "--from", "trunk", "--local", "lo2", "--project", "A"], [
        "Auto-merging (18, 20) /m/A/trunk to /local/A/lo2 (base /m/A/trunk:18).",
        '===> Auto-merging (18, 20) /m/A/trunk to /local/A/lo2 (base /m/A/trunk:18).',
        "U   A/new-file",
        "New merge ticket: $test_uuid:/A/trunk:13"]);

is_output ($svk, "branch", ['--push', "--from", "trunk", "--local", "lo2", "--project", "A"], [
        "Auto-merging (18, 20) /m/A/trunk to /local/A/lo2 (base /m/A/trunk:18).",
        '===> Auto-merging (18, 20) /m/A/trunk to /local/A/lo2 (base /m/A/trunk:18).',
        "U   A/new-file",
        "New merge ticket: $test_uuid:/A/trunk:13",
        "Committed revision 21."]);

$svk->switch ("//m/A/trunk", $corpath_default);

append_file ("$corpath_default/A/new-file", "some text\n");
$svk->commit ('-m', 'modification to mirror', "$corpath_default");

my $oldwd = Cwd::getcwd;
chdir $corpath_default;
#is_output ($svk, "pull", ["//local/A/lo2"], [
is_output ($svk, "br", ['--pull', '--local', "lo2"], [
        "Auto-merging (20, 22) /m/A/trunk to /local/A/lo2 (base /m/A/trunk:20).",
        "U   A/new-file",
        "New merge ticket: $test_uuid:/A/trunk:14",
        "Committed revision 23."]);
chdir $oldwd;

#$svk->copy ('-m', '2nd branch', '//m', '//l2');
$svk->br('--create','lo3','--local','--project','A');
#$svk->checkout ('//l2', $corpath_second);
$svk->checkout ('//local/A/lo3', $corpath_second);
#$svk->br('--checkout','--local','lo3', $corpath_second);

is_output ($svk, "pull", [$corpath_default, $corpath_second], [
        "Syncing $uri",
        "Syncing //m/A/trunk(/m/A/trunk) in $corpath_default to 24.",
        "Syncing //local/A/lo3(/local/A/lo3) in $corpath_second to 24."]);

# XXX: br --pull not providing --all so far
#is_output ($svk, "branch", ['--pull', '-a','--project', 'A'], [ 
is_output ($svk, "pull", ['-a'], [
        "Syncing $uri",
        "Syncing //m/A/trunk(/m/A/trunk) in $corpath_default to 24.",
        "Syncing //local/A/lo3(/local/A/lo3) in $corpath_second to 24.",
        "Syncing /test/A/trunk(/A/trunk) in $corpath_test to 14.",
        __"U   $corpath_test/A/new-file"]);

append_file ("$corpath_default/A/new-file", "some text\n");
$svk->commit ('-m', 'modification to mirror', "$corpath_default");

#is_output ($svk, "pull", ['--lump', "//local/A/lo2"], [
is_output ($svk, "branch",
       ['--pull', '--lump', "--local", "lo2", '--project', 'A'],
       ["Auto-merging (22, 25) /m/A/trunk to /local/A/lo2 (base /m/A/trunk:22).",
        "U   A/new-file",
        "New merge ticket: $test_uuid:/A/trunk:15",
        "Committed revision 26."]);
