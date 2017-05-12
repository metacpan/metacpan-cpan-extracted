#!/usr/bin/perl -w
use Test::More tests => 4;
use strict;
use File::Path;
use Cwd;
use SVK::Test;

my ($xd, $svk) = build_test();
our $output;
my ($copath, $corpath) = get_copath();
$svk->mkdir ('-m', 'trunk', '//trunk');
my $tree = create_basic_tree ($xd, '//trunk');
$svk->cp ('-m', 'branch', '//trunk', '//local');

$svk->checkout ('//local', $copath);
chdir($copath);
# simple case
$svk->cp('//trunk/A' => '//trunk/A-cp', -m => 'copy A');

is_output ($svk, 'sm', ['-t'],
	   ['Auto-merging (3, 5) /trunk to /local (base /trunk:3).',
	    'A + A-cp',
	    qr'New merge ticket: .*:/trunk:5']);
is_output ($svk, 'st', [],
	   ['A + A-cp',
	    ' M  .']);

is_output ($svk, 'ci', [-m => 'commit the smerge from checkout'],
	   ['Committed revision 6.']);

$svk->cp('//trunk/me' => '//trunk/me.cp', -m => 'copy me');


is_output ($svk, 'sm', ['-t'],
	   ['Auto-merging (5, 7) /trunk to /local (base /trunk:5).',
	    'A + me.cp',
	    qr'New merge ticket: .*:/trunk:7']);

