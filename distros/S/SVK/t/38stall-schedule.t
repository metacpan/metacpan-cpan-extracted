#!/usr/bin/perl -w
use Test::More tests => 9;
use strict;
use File::Path;
use SVK::Test;
our $output;
my ($xd, $svk) = build_test();
my ($copath, $corpath) = get_copath ('stall-schedule');
my ($repospath, undef, $repos) = $xd->find_repos ('//', 1);
$svk->mkdir(-m => 'trunk', '//trunk');
$svk->checkout ('//trunk', $copath);
chdir ($copath);
mkdir ('A');
mkdir ('A/deep');
overwrite_file ("A/foo", "foobar");
overwrite_file ("A/deep/bar", "foobar");
overwrite_file ("A/deep/baz", "foobar");
$svk->add('A');
rmtree ['A/deep'];
$svk->commit(-m => 'commit', 'A');

mkdir ('A/deep');
is_output($svk, 'st', ['A'], [__('?   A/deep')],
	  'commit clears stalled schedule');

$svk->add('A/deep');
$svk->mkdir(-m => 'mkdir', '//trunk/A/deep');
$svk->up('-C');

is($xd->{checkout}->get( SVK::Path::Checkout->copath($corpath, 'A/deep'))->{'.schedule'},
   'add', "update -C doesn't unschedule addmerge");
$svk->up;

ok(!$xd->{checkout}->get
   (SVK::Path::Checkout->copath($corpath, 'A/deep'))->{'.schedule'},
   'up add-merge clears stalled schedule');

$svk->mkdir('A/stall');
unlink('A/stall');

$svk->cp(-m => 'branch', '//trunk@2' => '//branch-A');
is_output($svk, 'switch', ['//branch-A'],
	  ['Syncing //trunk(/trunk) in '.__($corpath).' to 4.',
	   __('D   A/deep')]);

is_output($svk, 'mkdir', ['A/stall'],
	  [__('A/stall already added.')]);

is_output($svk, 'st', [],
	  [__('A   A/stall')]);

$svk->revert('A/stall');
rmtree['A/stall'];

is_output($svk, 'sm', ['//trunk'],
	  ['Auto-merging (2, 3) /trunk to /branch-A (base /trunk:2).',
	   __('A   A/deep'),
	   qr'New merge ticket: .*:/trunk:3']);

is_output($svk, 'st', [],
	  [__('A   A/deep'),
	   ' M  .']);

is_output($svk, 'revert', ['-R'],
	  [__('Reverted A/deep'),
	   'Reverted .']);
