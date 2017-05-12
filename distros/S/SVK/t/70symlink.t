#!/usr/bin/perl -w
use strict;
use Test::More tests => 54;
use SVK::Test;

use SVK::Util qw( HAS_SYMLINK is_symlink);

our $output;
my ($xd, $svk) = build_test();
my ($copath, $corpath) = get_copath ('symlink');

my @symlinks;
sub _symlink {
    my ($from, $to) = @_;
    push @symlinks, $to;
    return symlink($from => $to) if HAS_SYMLINK;
    overwrite_file ($to, "link $from");
}

sub _fix_symlinks {
    $svk->ps('svn:special' => '*', @symlinks) if !HAS_SYMLINK && @symlinks;
    @symlinks = ();
}

sub _check_symlinks1 {
    unless (HAS_SYMLINK) {
	ok(1); ok(1); return;
    }
    # doesn't work on a single target
    is_output ($svk, 'pg', ['svn:special', @_],
	       [map { "$_ - *" } @_], 'got svn:special');
    return 1;
}

sub _check_symlinks2 {
    for (@_) {
	ok (0, "$_ is symlink"), return if HAS_SYMLINK and !is_symlink ($_);
    }
    ok (1, 'paths are symlinks');
}

sub _check_symlinks {
    my (@params) = @_;

    return unless _check_symlinks1(@params);
    _check_symlinks2(@params);
}

$svk->checkout ('//', $copath);
mkdir ("$copath/A");
overwrite_file ("$copath/A/bar", "foobar\n");
_symlink ("bar", "$copath/A/bar.lnk");
_symlink ('/tmp', "$copath/A/dir.lnk");
is_output ($svk, 'add', ["$copath/A"],
	   [__"A   $copath/A",
	    __"A   $copath/A/bar",
	    __"A   $copath/A/bar.lnk",
	    __"A   $copath/A/dir.lnk"], 'add symlinks');
_symlink ('/non-exists', "$copath/A/non.lnk");
is_output ($svk, 'add', ["$copath/A/non.lnk"],
	   [__("A   $copath/A/non.lnk")], 'dangling symlink');
is_output ($svk, 'rm', ["$copath/A/non.lnk"],
	   [__("$copath/A/non.lnk is scheduled; use '--force' to go ahead.")]);
is_output ($svk, 'rm', ["$copath/A/bar.lnk"],
	   [__("$copath/A/bar.lnk is scheduled; use '--force' to go ahead.")]);
is_output ($svk, 'status', ["$copath/A"],
	   [__"A   $copath/A",
	    __"A   $copath/A/bar",
	    __"A   $copath/A/bar.lnk",
	    __"A   $copath/A/dir.lnk",
	    __"A   $copath/A/non.lnk"], 'status added symlinks');
my @allsymlinks = @symlinks;
_fix_symlinks();
_check_symlinks (@allsymlinks);

$svk->commit ('-m', 'init', $copath);
rmtree [$copath];
is_output ($svk, 'checkout', ['//', $copath],
	   ["Syncing //(/) in $corpath to 1.",
	    __"A   $copath/A",
	    __"A   $copath/A/dir.lnk",
	    __"A   $copath/A/bar",
	    __"A   $copath/A/bar.lnk",
	    __"A   $copath/A/non.lnk"], 'checkout symlinks');

is_output ($svk, 'status', [$copath], [], 'unmodified status');
_check_symlinks (@allsymlinks);

unlink ("$copath/A/dir.lnk");
_symlink ('.', "$copath/A/dir.lnk");

is_output ($svk, 'status', [$copath],
	   [__("M   $copath/A/dir.lnk")], 'modified status');

_check_symlinks (@allsymlinks);
is_output ($svk, 'diff', [$copath],
	   [__('=== t/checkout/symlink/A/dir.lnk'),
	    '==================================================================',
	    __("--- t/checkout/symlink/A/dir.lnk\t(revision 1)"),
	    __("+++ t/checkout/symlink/A/dir.lnk\t(local)"),
	    '@@ -1 +1 @@',
	    '-link /tmp',
            '\ No newline at end of file',
            '+link .',
            '\ No newline at end of file'], 'modified diff');

$svk->revert ("$copath/A/dir.lnk");
_check_symlinks (@allsymlinks);
is_output ($svk, 'status', [$copath], [], 'revert');

$svk->cp ('//A/non.lnk', "$copath/non.lnk.cp");
ok (_l("$copath/non.lnk.cp"), 'copy');
_fix_symlinks();
_check_symlinks (@allsymlinks, "$copath/non.lnk.cp");
is_output ($svk, 'commit', ['-m', 'add copied symlink', $copath],
	   ['Committed revision 2.']);

$svk->cp ('-m', 'make branch', '//A', '//B');
# XXX: commit and then update will break checkout optimization,
# make a separate test for that
$svk->update ($copath);
unlink ("$copath/B/dir.lnk");
_symlink ('.', "$copath/B/dir.lnk");

_check_symlinks (map {s{/A}{/B}; $_} @allsymlinks);
_fix_symlinks();
$svk->commit ('-m', 'change something', "$copath/B");
is_output ($svk, 'status', [$copath], [], 'committed');

$svk->smerge ('-C', '//B', "$copath/A");
# Symlink correction adds a revision
my $baserev = (HAS_SYMLINK ? 1 : 2);
is_output ($svk, 'smerge', ['--no-ticket', '//B', "$copath/A"],
	   ["Auto-merging (0, 4) /B to /A (base /A:$baserev).",
	    __("U   $copath/A/dir.lnk")], 'merge');
is_output ($svk, 'diff', [$copath],
	   [__('=== t/checkout/symlink/A/dir.lnk'),
	    '==================================================================',
	    __("--- t/checkout/symlink/A/dir.lnk\t(revision 4)"),
	    __("+++ t/checkout/symlink/A/dir.lnk\t(local)"),
	    '@@ -1 +1 @@',
	    '-link /tmp',
            '\ No newline at end of file',
            '+link .',
            '\ No newline at end of file'], 'merge');

_symlink ('non', "$copath/B/new-non.lnk");
$svk->import ('--force', '-m', 'use import', '//', $copath);
unlink ("$copath/B/new-non.lnk");
$svk->revert ('-R', "$copath/B");
ok (_l("$copath/B/new-non.lnk"), 'import sets auto prop too');

is_output ($svk, 'status', [$copath], [], 'import');

$svk->rm ("$copath/B/new-non.lnk");

is_output ($svk, 'status', [$copath],
	   [__('D   t/checkout/symlink/B/new-non.lnk')], 'delete');
overwrite_file ("$copath/B/new-non.lnk", "foobar\n");
is_output ($svk, 'add', ["$copath/B/new-non.lnk"],
	   [__('R   t/checkout/symlink/B/new-non.lnk')], 'replace symlink with normal file');

_fix_symlinks();
is_output ($svk, 'commit', ['-m', 'change to non-link', $copath],
	   ['Committed revision 6.']);
$svk->update ('-r5', $copath);
ok (_l("$copath/B/new-non.lnk"), 'update from file to symlink');
$svk->update ($copath);
ok (-e "$copath/B/new-non.lnk", 'update from symlink to file');

$svk->rm ("$copath/B/new-non.lnk");
_symlink ('non', "$copath/B/new-non.lnk");
is_output ($svk, 'add', ["$copath/B/new-non.lnk"],
	   [__('R   t/checkout/symlink/B/new-non.lnk')], 'replace normal file with symlink');
is_output ($svk, 'st', [$copath],
	   [__('R   t/checkout/symlink/B/new-non.lnk')]);
is_output ($svk, 'commit', ['-m', 'change to non-link', $copath],
	   ['Committed revision 7.']);

unlink ("$copath/B/dir.lnk");
_symlink ('/tmp', "$copath/B/dir.lnk");
is_output ($svk, 'commit', ['-m', "change dir.lnk", "$copath/B/dir.lnk"],
	   ['Committed revision 8.']);

$svk->rm ("$copath/A/dir.lnk");
overwrite_file ("$copath/A/dir.lnk", "link /tmp");
is_output ($svk, 'add', ["$copath/A/dir.lnk"],
	   [__("R   $copath/A/dir.lnk")], 'replace symlink with normal file of same content');
is_output ($svk, 'status', [$copath],
	   [__("R   $copath/A/dir.lnk")], 'replace symlink with normal file of same content');
$svk->commit (-m => 'change a symlink to normal file', $copath);
@allsymlinks = grep {!m/dir.lnk/} @allsymlinks;
is_output ($svk, 'status', [$copath], [], 'committed');

$svk->rm ("$copath/A/dir.lnk");
_symlink ('non', "$copath/A/dir.lnk");
is_output ($svk, 'add', ["$copath/A/dir.lnk"],
	   [__("R   $copath/A/dir.lnk")], 'replace with symlink to nonexist');
_fix_symlinks();
is_output ($svk, 'commit', [-m => 'replace to symlink to nonexist', $copath],
	   ['Committed revision 10.']);

_symlink ('A', "$copath/entry.lnk");
$svk->add ("$copath/entry.lnk");
is_output ($svk, 'status', [$copath],
	   [__("A   $copath/entry.lnk")]);
_fix_symlinks();
is_output ($svk, 'revert', ["$copath/entry.lnk"],
	   [__"Reverted $copath/entry.lnk"]);
is_output ($svk, 'status', [$copath],
	   [__("?   $copath/entry.lnk")]);
unlink ("$copath/entry.lnk");

unlink ("$copath/non.lnk.cp");
overwrite_file ("$copath/non.lnk.cp", "hate\n");

SKIP: {
skip 'no real symlinks', 8 unless HAS_SYMLINK;

is_output ($svk, 'status', [$copath],
	   ["~   $copath/non.lnk.cp"], 'overwrite symlink with normal file');
is_output($svk, 'ci', [-m => 'bzz', '--import', $copath],
	  ['Committed revision 11.']);

is_output ($svk, 'status', [$copath], []);

unlink ("$copath/non.lnk.cp");
_symlink ('non', "$copath/non.lnk.cp");
_fix_symlinks();

is_output ($svk, 'status', [$copath],
	   ["~   $copath/non.lnk.cp"], 'change file back to symlink');

is_output($svk, 'ci', [-m => 'back to symlink with --import', '--import', $copath],
	  ['Committed revision 12.']);

$svk->revert ($copath);
is_output ($svk, 'status', [$copath], []);


# the first part of _check_symlinks currently passes but the second part fails.
# once both parts are passing revert back to a single call like the rest of the file.

_check_symlinks1 ("$copath/non.lnk.cp", "$copath/B/dir.lnk");

_check_symlinks2 ("$copath/non.lnk.cp", "$copath/B/dir.lnk");

}
