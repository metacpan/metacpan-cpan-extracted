#!/usr/bin/perl -w
use Test::More tests => 2;
use strict;
use File::Path;
use SVK::Test;

# test for merging a cp with deletion inside
my ($xd, $svk) = build_test();
our $output;
my ($copath, $corpath) = get_copath('smerge-cpdelete');
my $depot = $xd->find_depot('');
$svk->mkdir ('-m', 'trunk', '//trunk');
my $tree = create_basic_tree ($xd, '//trunk');
$svk->cp ('-m', 'branch', '//trunk', '//local');

$svk->cp(-m => 'cp B', '//trunk/B' => '//trunk/B-cp');
$svk->rm(-m => 'rm B/fe', '//trunk/B-cp/fe');
$svk->mkdir(-m => 'new dir', '//trunk/Anewdir');
is_output($svk, 'smerge', [-m => 'merge cp with delete', -t => '//local'],
	  ['Auto-merging (3, 7) /trunk to /local (base /trunk:3).',
	   'A + B-cp',
	   'D   B-cp/fe',
	   'A   Anewdir',
	   qr'New merge ticket: .*:/trunk:7',
	   'Committed revision 8.']);

is_output($svk, 'ls', ['//local/B-cp'],
	  ['S/'], 'fe should be deleted in local as well');
# XXX test merging to mirror.


