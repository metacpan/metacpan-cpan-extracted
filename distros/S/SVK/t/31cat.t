#!/usr/bin/perl -w
use Test::More tests => 9;
use strict;
use SVK::Test;
our $output;
my ($xd, $svk) = build_test();
my ($copath, $corpath) = get_copath ('cat');
my ($repospath, undef, $repos) = $xd->find_repos ('//', 1);
$svk->checkout ('//', $copath);
is_output_like ($svk, 'cat', [], qr'SYNOPSIS', 'cat - help');

chdir ($copath);
mkdir ('A');
overwrite_file ("A/foo", "foobar\n");
overwrite_file ("A/bar", "\$Revision\$\n");
$svk->add ('A');
$svk->ps ('svn:keywords', 'Revision', 'A/bar');
$svk->commit ('-m', 'init');
append_file ('A/foo', "barbar\n");
append_file ('A/bar', "barbar\n");
$svk->ps ('svn:keywords', 'FileRev', 'A/foo');
$svk->commit ('-m', 'modify');

is_output ($svk, 'cat', ['A/foo'], [qw/foobar barbar/]);
is_output ($svk, 'cat', ['//A/foo'], [qw/foobar barbar/]);
is_output ($svk, 'cat', ['-r1', 'A/foo'], ['foobar'],
	   'cat -rN copath');
is_output ($svk, 'cat', ['-r1', '//A/foo'], ['foobar'],
	  'cat -rN depotpath');
is_output ($svk, 'cat', ['A/bar'], ['$Revision: 2 $', 'barbar'],
	  'cat - with keyword');

$svk->mv(-m => 'rename', '//A/foo' => '//A/foo.new');

is_output ($svk, 'cat', ['-r1', '//A/foo.new'], ['foobar'],
	   "cat -rN depotpath peg'ed");

is_output($svk, 'cat', ['-r1', '//A/foo'], ['foobar']);

is_output ($svk, 'cat', ['-r1', '//A/foo@2'], ['foobar']);
