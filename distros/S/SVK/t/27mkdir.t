#!/usr/bin/perl -w
use strict;
use SVK::Test;
use Test::More tests => 22;

our $output;
my ($xd, $svk) = build_test('test');
my ($copath, $corpath) = get_copath ('mkdir');
my ($repospath, $path, $repos) = $xd->find_repos ('/test/', 1);

set_editor(<< 'TMP');
$_ = shift;
open _ or die $!;
@_ = <_>;
# simulate some editing, for --template test
s/monkey/gorilla/g for @_;
s/birdie/parrot/g for @_;
close _;
unlink $_;
open _, '>', $_ or die $!;
print _ @_;
close _;
print @_;
TMP

$svk->checkout ('//', $copath);
is_output_like ($svk, 'mkdir', [], qr'SYNOPSIS', 'mkdir - help');
is_output_like ($svk, 'mkdir', ['nonexist'],
		qr'not a checkout path');

is_output ($svk, 'mkdir', ['-m', 'msg', '//'],
	   ['The path // already exists.']);

is_output ($svk, 'mkdir', ['-m', 'msg', '//newdir'],
	   ['Committed revision 1.']);

is_output ($svk, 'mkdir', ['-m', 'msg', '//newdir'],
	   ['The path //newdir already exists.']);

is_output ($svk, 'mkdir', ['-m', 'msg', '//i-newdir/deep'],
	   [qr'.*',
	    'Please update checkout first.']);

is_output ($svk, 'mkdir', ['-p', '-m', 'msg monkey foo', '--template', '//i-newdir/deep'],
	   ['Waiting for editor...',
	    'Committed revision 2.']);

is_output_like ($svk, 'log', [-r => 2, '//i-newdir/deep'],
		qr/msg gorilla foo/, 'mkdir template works');

is_output ($svk, 'mkdir', ['-p', '-m', 'msg', '//i-newdir/deeper/file'],
	   ['Committed revision 3.']);

is_output ($svk, 'mkdir', ["$copath/c-newfile"],
      [__"A   $copath/c-newfile"]);

is_output ($svk, 'mkdir', ["$copath/c-newdir/deeper"],
      [qr"use -p."]);

is_output ($svk, 'mkdir', ['-p', "$copath/c-newdir/deeper"],
      [__"A   $copath/c-newdir",
       __"A   $copath/c-newdir/deeper"]);

is_output ($svk, 'mkdir', ['-p', "$copath/foo", "$copath/bar"],
     [__"A   $copath/foo",
      __"A   $copath/bar"]);

is_output ($svk, 'mkdir', ['-p', "$copath/d-newdir/foo", "$copath/e-newdir"],
     [__"A   $copath/d-newdir",
      __"A   $copath/d-newdir/foo",
      __"A   $copath/e-newdir"]);

SKIP: {
skip 'SVN::Mirror not installed', 4
    unless HAS_SVN_MIRROR;

my $uri = uri($repospath);

$svk->mirror ('//m', $uri.($path eq '/' ? '' : $path));
$svk->sync ('//m');

is_output ($svk, 'mkdir', ['-m', 'msg', '//m/dir-on-source'],
	   ["Merging back to mirror source $uri.",
	    'Merge back committed as revision 1.',
	    "Syncing $uri",
	    'Retrieving log information from 1 to 1',
	    'Committed revision 5 from revision 1.']);

is_output ($svk, 'mkdir', ['-m', 'msg', '//m/source/deep'],
	   ["Merging back to mirror source $uri.",
	    qr'.*',
	    'Please sync mirrored path /m first.']);

is_output ($svk, 'mkdir', ['-p', '-m', 'msg', '//m/source/deep'],
	   ["Merging back to mirror source $uri.",
	    'Merge back committed as revision 2.',
	    "Syncing $uri",
	    'Retrieving log information from 2 to 2',
	    'Committed revision 6 from revision 2.']);

is_output ($svk, 'mkdir', ['-p', '-m', 'msg', '//m/source/deep'],
	   ['The path //m/source/deep already exists.']);
}

is_output ($svk, 'mkdir', ["$copath/f-newdir/foo", "$copath/g-newdir"],
     [qr"use -p."]);


is_output ($svk, 'mkdir', ["$copath/f-newdir", "//g-newdir/orz"],
	   ['Path //g-newdir is not a checkout path.']);

is_output ($svk, 'mkdir', [-m => 'more than one',
			   "//m/f-newdir", "//m/orz"],
	   [qr'not supported']);

# different mirror
is_output ($svk, 'mkdir', [-m => 'more than one',
			   "//m/f-newdir", "//uorz"],
	   [qr'not supported']);


