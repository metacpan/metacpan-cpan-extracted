#!/usr/bin/perl -w
use strict;
use Test::More tests => 20;
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

my $trunk = '/mirror/MyProject/trunk';
my ($copath, $corpath) = get_copath ('bm-move');
$svk->checkout('/'.$trunk,$copath);
chdir($copath);

is_output ($svk, 'branch', ['--create', 'feature/foo'],
    ["Merging back to mirror source $uri.",
     "Merge back committed as revision 6.",
     "Syncing $uri",
     'Retrieving log information from 6 to 6',
     'Committed revision 7 from revision 6.',
     'Project branch created: feature/foo']);
is_output ($svk, 'branch', ['--list'], ['feature/foo']);

is_output ($svk, 'branch', ['--move', 'feature/foo', 'release-ready/bar'],
    ["Merging back to mirror source $uri.",
     "Merge back committed as revision 7.",
     "Syncing $uri",
     "Retrieving log information from 7 to 7",
     "Committed revision 8 from revision 7."]);
is_output ($svk, 'branch', ['--list'], ['release-ready/bar']);

is_output ($svk, 'branch', ['--move', 'release-ready/bar', 'feature/'],
    ["Merging back to mirror source $uri.",
     "Merge back committed as revision 8.",
     "Syncing $uri",
     "Retrieving log information from 8 to 8",
     "Committed revision 9 from revision 8."]);
is_output ($svk, 'branch', ['--list'], ['feature/bar']);

is_output ($svk, 'branch', ['--create', 'feature/moo'],
    ["Merging back to mirror source $uri.",
     "Merge back committed as revision 9.",
     "Syncing $uri",
     'Retrieving log information from 9 to 9',
     'Committed revision 10 from revision 9.',
     'Project branch created: feature/moo']);
is_output ($svk, 'branch', ['--move', 'feature/moo', 'feature/mar'],
    ["Merging back to mirror source $uri.",
     "Merge back committed as revision 10.",
     "Syncing $uri",
     "Retrieving log information from 10 to 10",
     "Committed revision 11 from revision 10."]);
is_output_unlike ($svk, 'branch', ['--list'], qr'feature/moo');

# create to local and move back
is_output ($svk, 'branch', ['--create', 'localfoo', '--local', '--switch-to'],
    ["Committed revision 12.",
     "Project branch created: localfoo (in local)",
     'Syncing /'."$trunk($trunk) in ".__($corpath).' to 12.']);

is_output ($svk, 'branch', ['--move', 'feature/remotebar'],
    ["Merging back to mirror source $uri.",
     "Merge back committed as revision 11.",
     "Syncing $uri",
     "Retrieving log information from 11 to 11",
     "Committed revision 13 from revision 11.",
     'Auto-merging (0, 12) /local/MyProject/localfoo to /mirror/MyProject/branches/feature/remotebar (base /mirror/MyProject/trunk:6).',
     '===> Auto-merging (0, 12) /local/MyProject/localfoo to /mirror/MyProject/branches/feature/remotebar (base /mirror/MyProject/trunk:6).',
     "Merging back to mirror source $uri.",'Empty merge.',
     "Committed revision 14.",
     "Syncing //local/MyProject/localfoo(/local/MyProject/localfoo) in ".
      __($corpath)." to 14."]);

is_output ($svk, 'branch', ['--list'],
    ['feature/bar','feature/mar','feature/remotebar'],
    'Move localfoo to remotebar, cross depot move');

# create to local, not switched, and then move back
is_output ($svk, 'branch', ['--create', 'localbar', '--local'],
    ["Committed revision 15.",
     "Project branch created: localbar (in local)"]);

is_output ($svk, 'branch', ['--move', '//local/MyProject/localbar', 'feature/remotefoo'],
    ["Merging back to mirror source $uri.",
     "Merge back committed as revision 12.",
     "Syncing $uri",
     "Retrieving log information from 12 to 12",
     "Committed revision 16 from revision 12.",
     'Auto-merging (0, 15) /local/MyProject/localbar to /mirror/MyProject/branches/feature/remotefoo (base /mirror/MyProject/trunk:6).',
     '===> Auto-merging (0, 15) /local/MyProject/localbar to /mirror/MyProject/branches/feature/remotefoo (base /mirror/MyProject/trunk:6).',
     "Merging back to mirror source $uri.",'Empty merge.',
     "Committed revision 17."]);

is_output ($svk, 'info', ['//local/MyProject/localbar'],
    ['Path //local/MyProject/localbar does not exist.']);

is_output ($svk, 'branch', ['--list'],
    ['feature/bar','feature/mar','feature/remotebar','feature/remotefoo'],
    'Move localbar to remotefoo, cross depot move w/o switch to local');

$svk->mkdir('//mirror/MyProject/branches/hasbugs', -m => '- bugs dir');
is_output ($svk, 'branch', ['--move', 'feature/bar', 'feature/mar', 'hasbugs/'],
    ["Merging back to mirror source $uri.",
     "Merge back committed as revision 14.",
     "Syncing $uri",
     "Retrieving log information from 14 to 14",
     "Committed revision 19 from revision 14.",
     "Merging back to mirror source $uri.",
     "Merge back committed as revision 15.",
     "Syncing $uri",
     "Retrieving log information from 15 to 15",
     "Committed revision 20 from revision 15."]);

is_output ($svk, 'branch', ['--list'],
    ['feature/remotebar','feature/remotefoo', 'hasbugs/bar','hasbugs/mar'],
    'branch --list. check if feature/bar,mar moved to hasbugs/');

is_output ($svk, 'branch', ['--create', 'localbar', '--local'],
    ["Committed revision 21.",
     "Project branch created: localbar (in local)"]);

is_output ($svk, 'branch', ['--move', 'hasbugs/bar', 'hasbugs/mar'],
    ['Project branch already exists: hasbugs/mar']);
