#!/usr/bin/perl -w
use strict;
use Test::More tests => 10;
use SVK::Test;
use File::Path;

my ($xd, $svk) = build_test('test');
our $output;
$svk->mkdir(-m => 'trunk', '/test/trunk');
$svk->mkdir(-m => 'trunk', '/test/branches');
$svk->mkdir(-m => 'trunk', '/test/tags');
my $tree = create_basic_tree($xd, '/test/trunk');

my $depot = $xd->find_depot('test');
my $uri = uri($depot->repospath);

$svk->mirror('//mirror/MyProject', $uri);
$svk->sync('//mirror/MyProject');

my ($copath, $corpath) = get_copath ('bm-create');
$svk->checkout('//mirror/MyProject/trunk',$copath);
chdir($copath);

is_output_like ($svk, 'branch', ['--create', 'feature/foo'], qr'Project branch created: feature/foo');
is_output_like ($svk, 'branch',
    ['--create', 'feature/bar', '--switch-to'],
    qr'Project branch created: feature/bar');

overwrite_file ('A/Q/qu', "\nonly a bar\nzz\n");
$svk->diff();
$svk->commit ('-m', 'commit message here (r9)','');

is_output ($svk, 'branch',
    ['--create', 'localfoo', '--local'],
    ["Committed revision 10.",
     "Project branch created: localfoo (in local)"]);

$svk->branch('--switch', 'trunk');

is_output ($svk, 'branch',
    ['--create', 'localbar', '--local', '--switch-to'],
    ["Committed revision 11.",
     "Project branch created: localbar (in local)",
     'Syncing /'."/mirror/MyProject/trunk(/mirror/MyProject/trunk) in ".__($corpath).' to 11.']);

is_output ($svk, 'branch',
    ['--create', 'feature/foobar', '--from', 'feature/bar'],
    ["Merging back to mirror source $uri.",
     "Merge back committed as revision 9.",
     "Syncing $uri",
     'Retrieving log information from 9 to 9',
     'Committed revision 12 from revision 9.',
     "Project branch created: feature/foobar (from branch feature/bar)"]);

is_output ($svk, 'info',['//mirror/MyProject/branches/feature/foobar'],
    ["Depot Path: //mirror/MyProject/branches/feature/foobar",
     "Project name: MyProject",
     "Revision: 12", "Last Changed Rev.: 12",
     qr/Last Changed Date: \d{4}-\d{2}-\d{2}/,
     "Mirrored From: $uri, Rev. 9",
     "Copied From: /mirror/MyProject/branches/feature/bar, Rev. 9",
     "Copied From: /mirror/MyProject/trunk, Rev. 6",
     "Merged From: /mirror/MyProject/branches/feature/bar, Rev. 9",
     "Merged From: /mirror/MyProject/trunk, Rev. 6",'']);

is_output ($svk, 'branch',
    ['--create', 'feature/footrunk', '--from', 'trunk'],
    ["Merging back to mirror source $uri.",
     "Merge back committed as revision 10.",
     "Syncing $uri",
     'Retrieving log information from 10 to 10',
     'Committed revision 13 from revision 10.',
     "Project branch created: feature/footrunk"]);

is_output ($svk, 'branch',
    ['--create', 'release-1', '--tag', '--from', 'feature/bar'],
    ["Merging back to mirror source $uri.",
     "Merge back committed as revision 11.",
     "Syncing $uri",
     'Retrieving log information from 11 to 11',
     'Committed revision 14 from revision 11.',
     "Project tag created: release-1 (from branch feature/bar)"]);

is_output ($svk, 'branch',
    ['--create', 'bug-in-release-1', '--from-tag', 'release-1'],
    ["Merging back to mirror source $uri.",
     "Merge back committed as revision 12.",
     "Syncing $uri",
     'Retrieving log information from 12 to 12',
     'Committed revision 15 from revision 12.',
     "Project branch created: bug-in-release-1 (from tag release-1)"]);

#$svk->br("--info", "bug-in-release-10"
is_output ($svk, 'info',['//mirror/MyProject/branches/bug-in-release-1'],
    ["Depot Path: //mirror/MyProject/branches/bug-in-release-1",
     "Project name: MyProject",
     "Revision: 15", "Last Changed Rev.: 15",
     qr/Last Changed Date: \d{4}-\d{2}-\d{2}/,
     "Mirrored From: $uri, Rev. 12",
     "Copied From: /mirror/MyProject/tags/release-1, Rev. 14",
     "Copied From: /mirror/MyProject/branches/feature/bar, Rev. 9",
     "Copied From: /mirror/MyProject/trunk, Rev. 6",
     "Merged From: /mirror/MyProject/tags/release-1, Rev. 14",
     "Merged From: /mirror/MyProject/branches/feature/bar, Rev. 9",
     "Merged From: /mirror/MyProject/trunk, Rev. 6",'']);
