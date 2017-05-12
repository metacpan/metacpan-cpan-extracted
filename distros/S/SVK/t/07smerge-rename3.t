#!/usr/bin/perl -w

#
# Tests that smerge handles updates after renames have been made
#

use Test::More tests => 11;
use strict;
use File::Path;
use Cwd;
use SVK::Test;

my ($xd, $svk) = build_test();
our ($answer, $output);
my ($co_trunk_rpath, $co_trunk_path) = get_copath ('smerge-rename3-trunk');
my ($co_branch_rpath, $co_branch_path) = get_copath ('smerge-rename3-branch');
my ($repospath, undef, $repos) = $xd->find_repos ('//', 1);
my $uuid = $repos->fs->get_uuid;

# Setup the trunk
$svk->mkdir ('-m', 'trunk', '//trunk');
$svk->checkout ('//trunk', $co_trunk_path);

# Create some data in trunk
chdir($co_trunk_path);
$svk->mkdir('module');
overwrite_file('module/test.txt', '1');
$svk->add('module/test.txt');
$svk->ci(-m => "test 1");

# Make a copy
$svk->mkdir ('-m', 'branches', '//branches');
$svk->cp(-m => 'newbranch', '//trunk', '//branches/newbranch');
$svk->checkout ('//branches/newbranch', $co_branch_path);
is_file_content("$co_branch_path/module/test.txt", '1');

# Rename the module in the branch
chdir($co_branch_path);
$svk->move('module', 'module2');
$svk->commit(-m => "renamed");

# Make a change to trunk
chdir($co_trunk_path);
overwrite_file('module/test.txt', '2');
$svk->ci(-m => "test 2");

# Merge changes w/rename from trunk to branch
is_output ($svk, 'smerge', ['//trunk', '//branches/newbranch', '--track-rename', '-m', 'merge 1'], [
    'Auto-merging (2, 6) /trunk to /branches/newbranch (base /trunk:2).',
    'Collecting renames, this might take a while.',
    'U   module/test.txt - module2/test.txt',
    "New merge ticket: $uuid:/trunk:6",
    'Committed revision 7.',
]);

# Update the branch
chdir($co_branch_path);
$svk->update();
is_file_content('module2/test.txt', '2');

# Make another change to trunk
chdir($co_trunk_path);
overwrite_file('module/test.txt', '3');
$svk->ci(-m => "test 3");


# Merge changes w/rename from trunk to branch
is_output ($svk, 'smerge', ['//trunk', '//branches/newbranch', '--track-rename', '-m', 'merge 2'], [
    'Auto-merging (6, 8) /trunk to /branches/newbranch (base /trunk:6).',
    'Collecting renames, this might take a while.',
    'U   module/test.txt - module2/test.txt',
    "New merge ticket: $uuid:/trunk:8",
    'Committed revision 9.',
]);

# Update the branch
chdir($co_branch_path);
$svk->update();
is_file_content('module2/test.txt', '3');

append_file('module2/test.txt', '4');
$svk->ci(-m => "test 4");

# Merge changes w/rename from trunk to branch
# NOTE: This expected output might not be completely correct!

is_output ($svk, 'smerge', ['//branches/newbranch', '//trunk', '--track-rename', '-m', 'merge back'], [
    'Auto-merging (0, 10) /branches/newbranch to /trunk (base /trunk:8).',
    'Collecting renames, this might take a while.',
    'A + module2',
    'U   module2/test.txt',
    'D   module',
    "New merge ticket: $uuid:/branches/newbranch:10",
    'Committed revision 11.',
]);

chdir($co_trunk_path);
$svk->update();
is_file_content('module2/test.txt', '34');

# adding a new dir on trunk
$svk->mkdir('foo');
overwrite_file('foo/test.txt', 'a');
$svk->add('foo/test.txt');
$svk->ci(-m => "new module added");

# Merge changes w/rename from trunk to branch
is_output ($svk, 'smerge', ['//trunk', '//branches/newbranch', '--track-rename', '-m', 'merge 3'], [
    'Auto-merging (8, 12) /trunk to /branches/newbranch (base /branches/newbranch:10).',
    'Collecting renames, this might take a while.',
    'A   foo',
    'A   foo/test.txt',
    "New merge ticket: $uuid:/trunk:12",
    'Committed revision 13.',
]);

chdir($co_branch_path);
$svk->update();
is_file_content('foo/test.txt', 'a');

$svk->move('foo', 'bar');
overwrite_file('bar/test.txt', 'b');
$svk->ci(-m => "test 6 - renamed and changed");

is_output ($svk, 'smerge', ['//branches/newbranch', '//trunk', '--track-rename', '-m', 'merge back'], [
    'Auto-merging (10, 14) /branches/newbranch to /trunk (base /trunk:12).',
    'Collecting renames, this might take a while.',
    'A + bar',
    'U   bar/test.txt',
    'D   foo',
    "New merge ticket: $uuid:/branches/newbranch:14",
    'Committed revision 15.',
]);

chdir($co_trunk_path);
$svk->update();
is_file_content('bar/test.txt', 'b');

