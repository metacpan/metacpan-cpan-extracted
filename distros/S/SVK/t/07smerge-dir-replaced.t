#!/usr/bin/perl -w
use Test::More tests => 2;
use strict;
use File::Path;
use Cwd;
use SVK::Test;

my ($xd, $svk) = build_test();
our $output;
my ($copath, $corpath) = get_copath ('smerge-dir-replaced');
$svk->mkdir ('-m', 'trunk', '//trunk');
my $tree = create_basic_tree ($xd, '//trunk');

$svk->cp(-m => 'branch', '//trunk', '//local');

$svk->checkout ('//trunk', $copath);
chdir($copath);
$svk->mkdir("A/newlevel");
$svk->mv("A/be", "A/newlevel");

$svk->commit(-m => 'mv be into newlevel');
is_output($svk, 'sm', [-m => 'merge down', -t => '//local'],
	  ['Auto-merging (3, 5) /trunk to /local (base /trunk:3).',
	   'A   A/newlevel',
	   'A + A/newlevel/be',
	   'D   A/be',
	   qr'New merge ticket: .*:/trunk:5',
	   'Committed revision 6.']);

append_file('A/newlevel/be', "foobar\n");
$svk->ci(-m => 'change stuff at trunk.');

$svk->sw('//local');

$svk->rm('A/newlevel');
$svk->mv('A/Q', 'A/newlevel');
append_file('A/newlevel/qu', "fscked\n");
$svk->cp('//trunk/B/fe' => 'A/newlevel');
$svk->ci(-m => 'move things around on local');

TODO: {
local $TODO = 'this test is suspicious, we shall investigate later';
# XXX: THIS IS TOTALLY WRONG
# this merge should be a replace of A/newlevel on trunk with A/Q
# and A/newlevel/qu should be added as well as other things from A/Q
# //RUZ
is_output($svk, 'sm', [-Cf => '//local'],
	  ['Auto-merging (0, 8) /local to /trunk (base /trunk:5).',
	   '    A/newlevel/qu - skipped',
	   'D   A/Q',
	   'C   A/newlevel',
	   'C   A/newlevel/be',
	   qr'New merge ticket: .*:/local:8',
	   'Empty merge.',
	   '2 conflicts found.']);
}

# XXX: more tests to add deltas in the in replaced dir.
