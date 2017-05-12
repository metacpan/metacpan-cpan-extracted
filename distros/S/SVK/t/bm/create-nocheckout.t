#!/usr/bin/perl -w
use strict;
use Test::More tests => 6;
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

my ($copath, $corpath) = get_copath ('bm-create-nonwc');

is_output ($svk, 'branch', ['--create', 'feature/foo'],
    ["I can't figure out what project you'd like to create a branch in. Please",
     "either run '$0 branch --create' from within an existing checkout or specify",
     "a project root using the --project flag"]);

is_output_like ($svk, 'branch', ['--create', 'feature/foo', '//mirror/MyProject'],
    qr'Project branch created: feature/foo');

is_output ($svk, 'branch', ['--list', '//mirror/MyProject'],
    ['feature/foo']);
is_output ($svk, 'branch',
    ['--create', 'feature/foobar', '--from', 'feature/foo', '//mirror/MyProject'],
    ["Merging back to mirror source $uri.",
     "Merge back committed as revision 7.",
     "Syncing $uri",
     'Retrieving log information from 7 to 7',
     'Committed revision 8 from revision 7.',
     "Project branch created: feature/foobar (from branch feature/foo)"]);

is_output ($svk, 'info',['//mirror/MyProject/branches/feature/foobar'],
    ["Depot Path: //mirror/MyProject/branches/feature/foobar",
     "Project name: MyProject",
     "Revision: 8", "Last Changed Rev.: 8",
     qr/Last Changed Date: \d{4}-\d{2}-\d{2}/,
     "Mirrored From: $uri, Rev. 7",
     "Copied From: /mirror/MyProject/branches/feature/foo, Rev. 7",
     "Copied From: /mirror/MyProject/trunk, Rev. 6",
     "Merged From: /mirror/MyProject/branches/feature/foo, Rev. 7",
     "Merged From: /mirror/MyProject/trunk, Rev. 6",'']);

is_output ($svk, 'branch',
    ['--create', 'feature/footrunk', '--from', 'trunk', '//mirror/MyProject'],
    ["Merging back to mirror source $uri.",
     "Merge back committed as revision 8.",
     "Syncing $uri",
     'Retrieving log information from 8 to 8',
     'Committed revision 9 from revision 8.',
     "Project branch created: feature/footrunk"]);
