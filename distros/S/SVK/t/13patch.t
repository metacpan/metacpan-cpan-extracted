#!/usr/bin/perl -w
use strict;
use SVK::Test;
plan tests => 49;

use File::Copy qw( copy );
our $output;
# build another tree to be mirrored ourself
my ($xd, $svk) = build_test();
my ($xd2, $svk2) = build_test();

is_output_like ($svk, 'patch', [], qr'SYNOPSIS');
is_output_like ($svk, 'patch', ['blah'], qr'SYNOPSIS');
is_output ($svk, 'patch', ['--view'], ['Filename required.']);
is_output ($svk, 'patch', ['view'], ['Filename required.']);

$svk->mkdir ('-m', 'init', '//trunk');
my $tree = create_basic_tree ($xd, '//trunk');
my ($repospath, $path, $repos) = $xd->find_repos ('//trunk', 1);
my ($repospath2, undef, $repos2) = $xd2->find_repos ('//trunk', 1);
my $uri = uri($repospath);
$svk2->mirror ('//trunk', $uri.($path eq '/' ? '' : $path));
$svk2->sync ('//trunk');
$svk2->copy ('-m', 'local branch', '//trunk', '//local');

my ($copath, $corpath) = get_copath ('patch');
$svk2->checkout ('//local', $copath);

append_file ("$copath/B/fe", "fnord\n");
$svk2->commit ('-m', "modified on local", $copath);

my ($uuid, $uuid2) = map {$_->fs->get_uuid} ($repos, $repos2);

is_output ($svk2, 'smerge', ['-lm', '', '-P', '//local', '//local', '//trunk',],
	   ['Auto-merging (0, 6) /local to /trunk (base /trunk:4).',
	    "Patching locally against mirror source $uri/trunk.",
	    'Illegal patch name: //local.']);
TODO: {
local $TODO = "fail -P on merge to checkout";
is_output ($svk2, 'smerge', ['-lm', '', '-P', '-', '//trunk', $copath,],
	   ["-P doesn't go with checkout path as target"]);
}
is_output ($svk2, 'smerge', ['-lm', '', '-P', 'test-1', '//local', '//trunk'],
	   ['Auto-merging (0, 6) /local to /trunk (base /trunk:4).',
	    "Patching locally against mirror source $uri/trunk.",
	    'U   B/fe',
	    'Patch test-1 created.']);
is_output ($svk2, 'smerge', ['-lm', '', '-P', 'test-1', '//local', '//trunk'],
	   ['Auto-merging (0, 6) /local to /trunk (base /trunk:4).',
	    "Patching locally against mirror source $uri/trunk.",
	    qr'^file .*test-1\.patch already exists\.$',
          "use 'svk patch regen test-1' instead."]);

my $log1 = ['Log:',
	    qr'.*',
	    ' local branch',
	    qr'.*',
	    ' modified on local'];
#	    ''];
my $patch1 = ['',
	      '=== B/fe',
	      '==================================================================',
	      "--- B/fe\t(revision 3)",
	      "+++ B/fe\t(patch test-1 level 1)",
	      '@@ -1 +1,2 @@',
	      ' file fe added later',
	      '+fnord'];

is_output ($svk2, 'patch', ['--view', 'test-1'],
	   ['==== Patch <test-1> level 1',
	    "Source: $uuid2:/local:6 [local]",
	    "Target: $uuid:/trunk:3 [mirrored]",
            "        ($uri/trunk)",
	    @$log1, @$patch1]);

is_output ($svk2, 'smerge', ['-lm', '', '-P', '-', '//local', '//trunk'],
	   ['Auto-merging (0, 6) /local to /trunk (base /trunk:4).',
	    "Patching locally against mirror source $uri/trunk.",
	    'U   B/fe',
	    '==== Patch <-> level 1',
	    "Source: $uuid2:/local:6",
	    "Target: $uuid:/trunk:3",
            "        ($uri/trunk)",
	    @$log1,
            (map { join('-', split(/test-1/, $_)) } @$patch1),
            '',
            '==== BEGIN SVK PATCH BLOCK ====',
            qr'Version: svk .*',
            '',
            \'...',
            ]);

ok (-e "$xd2->{svkpath}/patch/test-1.patch");
mkdir ("$xd->{svkpath}/patch");
copy ("$xd2->{svkpath}/patch/test-1.patch" => "$xd->{svkpath}/patch/test-1.patch");
is_output ($svk, 'patch', ['--list'], ['test-1@1: ']);

my ($scopath, $scorpath) = get_copath ('patch1');
$svk->checkout ('//trunk', $scopath);
overwrite_file ("$scopath/B/fe", "on trunk\nfile fe added later\n");
$svk->commit ('-m', "modified on trunk", $scopath);

$svk->patch ('--view', 'test-1');
is_output ($svk, 'patch', [qw/--test test-1/], ['G   B/fe', 'Empty merge.'],
	   'patch still applicable from server.');

is_output ($svk, 'patch', ['--view', 'test-1'],
	   ['==== Patch <test-1> level 1',
	    "Source: $uuid2:/local:6",
	    "Target: $uuid:/trunk:3 [local] [updated]",
	    @$log1, @$patch1]);

$svk2->sync ('-a');

is_output ($svk2, 'patch', [qw/--test test-1/],
	   ["Checking locally against mirror source $uri/trunk.",
	    'G   B/fe',
	    'Empty merge.'],
	   'patch still applicable from original.');

is_output ($svk2, 'patch', ['--view', 'test-1'],
	   ['==== Patch <test-1> level 1',
	    "Source: $uuid2:/local:6 [local]",
	    "Target: $uuid:/trunk:3 [mirrored] [updated]",
            "        ($uri/trunk)",
	    @$log1, @$patch1]);

is_output ($svk2, 'patch', ['--update', 'test-1'],
	   ['G   B/fe']);

my $patch2 = [split ("\n", << "END_OF_DIFF")];

=== B/fe
==================================================================
--- B/fe\t(revision 4)
+++ B/fe\t(patch test-1 level 1)
\@\@ -1,2 +1,3 \@\@
 on trunk
 file fe added later
+fnord

END_OF_DIFF

is_output ($svk2, 'patch', ['--view', 'test-1'],
	   ['==== Patch <test-1> level 1',
	    "Source: $uuid2:/local:6 [local]",
	    "Target: $uuid:/trunk:4 [mirrored]",
            "        ($uri/trunk)",
	    @$log1, @$patch2]);

copy ("$xd2->{svkpath}/patch/test-1.patch" => "$xd->{svkpath}/patch/test-1.patch");

is_output ($svk, 'patch', [qw/--test test-1/], ['U   B/fe', 'Empty merge.'],
	   'patch applies cleanly on server.');

is_output ($svk2, 'patch', [qw/--test test-1/],
	   ["Checking locally against mirror source $uri/trunk.",
	    'U   B/fe',
	    'Empty merge.'],
	   'patch applies cleanly from local.');

is_output ($svk, 'patch', ['--view', 'test-1'],
	   ['==== Patch <test-1> level 1',
	    "Source: $uuid2:/local:6",
	    "Target: $uuid:/trunk:4 [local]",
	    @$log1, @$patch2]);

is_output ($svk, 'patch', ['--apply', 'test-1', $scopath, '--', '-C'],
	   [__("U   $scopath/B/fe"),
	    "New merge ticket: $uuid2:/local:6"]);
$svk2->cp ('-m', 'branch', '//trunk', '//patch-branch');
is_output ($svk2, 'patch', ['--apply', 'test-1', '//patch-branch', '--', '-C'],
	   ['U   B/fe',
	    'Empty merge.']);

overwrite_file ("$scopath/B/fe", "on trunk\nfile fe added later\nbzzzzz\n");

$svk->ci ('-Pfrom-ci-P', '-mTest', $scopath);
# check me
$svk->patch ('--view', 'from-ci-P');

$svk->commit ('-m', "modified on trunk", $scopath);
is_output ($svk, 'patch', [qw/--test test-1/],
	   ['C   B/fe', 'Empty merge.', '1 conflict found.',
	    'Please do a merge to resolve conflicts and regen the patch.'],
	   'patch not applicable due to conflicts.');
overwrite_file ("$copath/B/fe", "file fe added later\nbzzzzz\nfnord\n");
$svk2->commit ('-m', "catch up on local", $copath);
is_output ($svk2, 'patch', ['--view', 'test-1'],
	   ['==== Patch <test-1> level 1',
	    "Source: $uuid2:/local:6 [local] [updated]",
	    "Target: $uuid:/trunk:4 [mirrored]",
            "        ($uri/trunk)",
	    @$log1, @$patch2]);
is_output ($svk2, 'patch', [qw/--regen test-1/],
	   ['G   B/fe']);

is_output ($svk2, 'patch', ['--view', 'test-1'],
	   ['==== Patch <test-1> level 2',
	    "Source: $uuid2:/local:9 [local]",
	    "Target: $uuid:/trunk:4 [mirrored]",
            "        ($uri/trunk)",
	    @$log1,
	    qr'.*',
	    ' catch up on local',
	    '',
	    '=== B/fe',
	    '==================================================================',
	    "--- B/fe\t(revision 4)",
	    "+++ B/fe\t(patch test-1 level 2)",
	    '@@ -1,2 +1,4 @@',
	    ' on trunk',
	    ' file fe added later',
	    '+bzzzzz',
	    '+fnord']);

$svk2->sync ('-a');
is_output ($svk2, 'patch', ['--view', 'test-1'],
	   ['==== Patch <test-1> level 2',
	    "Source: $uuid2:/local:9 [local]",
	    "Target: $uuid:/trunk:4 [mirrored] [updated]",
            "        ($uri/trunk)",
	    @$log1,
	    qr'.*',
	    ' catch up on local',
	    '',
	    '=== B/fe',
	    '==================================================================',
	    "--- B/fe\t(revision 4)",
	    "+++ B/fe\t(patch test-1 level 2)",
	    '@@ -1,2 +1,4 @@',
	    ' on trunk',
	    ' file fe added later',
	    '+bzzzzz',
	    '+fnord']);

$svk->st ($scopath);
$svk->rm ("$scopath/me");
is_output ($svk, 'ci', ['-m', 'delete something', '-P', 'delete', $scopath],
	   ['Patch delete created.']);
TODO: {
local $TODO = 'later';

is_output ($svk2, 'patch', ['--update', 'test-1'],
	   ['G   B/fe']);
is_output ($svk, 'patch', [qw/--test test-1/], ['U   B/fe', 'Empty merge.']);
is_output ($svk2, 'patch', [qw/--test test-1/], ['U   B/fe', 'Empty merge.']);
}

$svk->rm ('-m', "removed //trunk", '//trunk');
is_sorted_output ($svk, 'patch', ['--list'],
	   ['test-1@1: [n/a]',
	    'from-ci-P@1: [n/a]',
	    'delete@1: [n/a]']);

is_output ($svk, 'patch', ['--view', 'test-1'],
	   ['==== Patch <test-1> level 1',
	    "Source: $uuid2:/local:6",
	    "Target: $uuid:/trunk:4 [local] [updated]",
	    @$log1, @$patch2]);

eval { $svk->patch ('--update', 'test-1') };
is ($@, '', "Can't update an non-applicable patch");

eval { $svk->patch ('--regen', 'test-1') };
is ($@, '', "Can't regenerate an non-applicable patch");

eval { $svk->patch ('--apply', 'test-1') };
is ($@, '', "Can't apply an non-applicable patch");

eval { $svk->patch ('apply', 'test-1') };
is ($@, '', "Can't apply an non-applicable patch");

eval { $svk->patch ('--delete', 'test-1') };
is ($@, '', 'Successfully deleted patch test-1');

$svk->mkdir(-m => "init", "//cptest");
my ($cp_copath, $cp_corpath) = get_copath ('copy-test');
$svk->checkout ('//cptest', $cp_copath);
overwrite_file ("$cp_copath/test-file", "first line\n");

is_output($svk, add => ["$cp_copath/test-file"], [__("A   $cp_copath/test-file")]);
is_output($svk, ci => ['-m', 'first file', $cp_copath], ["Committed revision 8."]);

is_output($svk, cp => ["$cp_copath/test-file", "$cp_copath/test-copy"], [__("A   $cp_copath/test-copy")]);
append_file("$cp_copath/test-copy", "new line in copy\n");

is_output($svk, status => ["$cp_copath"], [__("M + $cp_copath/test-copy")]);

is_output($svk, ci => ['-P', 'copytestpatch', '-m', 'copy and change', $cp_copath], ["Patch copytestpatch created."]);

$svk->mkdir(-pm => "init", "//cptest-deep/subdir/deeper");
($cp_copath, $cp_corpath) = get_copath ('copy-deep-test');
$svk->checkout ('//cptest-deep', $cp_copath);
overwrite_file ("$cp_copath/subdir/deeper/test-file", "first line\n");

is_output($svk, add => ["$cp_copath/subdir/deeper/test-file"], [__("A   $cp_copath/subdir/deeper/test-file")]);
is_output($svk, ci => ['-m', 'first file', $cp_copath], ["Committed revision 10."]);

is_output($svk, cp => ["$cp_copath/subdir", "$cp_copath/subdir-copy"],
          [__("A   $cp_copath/subdir-copy"),
           __("A   $cp_copath/subdir-copy/deeper"),
           __("A   $cp_copath/subdir-copy/deeper/test-file"),
          ]);
append_file("$cp_copath/subdir-copy/deeper/test-file", "new line in deep copy\n");

is_output($svk, status => ["$cp_copath"],
          [__("A + $cp_copath/subdir-copy"),
           __("M + $cp_copath/subdir-copy/deeper/test-file")]);

is_output($svk, ci => ['-P', 'copytestpatch-deep', '-m', 'copy and change', $cp_copath], ["Patch copytestpatch-deep created."]);
