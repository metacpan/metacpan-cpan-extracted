#!/usr/bin/perl -w
use Test::More tests => 5;
use strict;
use SVK::Test;
our $output;
my ($xd, $svk) = build_test();
my ($copath, $corpath) = get_copath ('status-conflict');

my ($repospath, undef, $repos) = $xd->find_repos ('//', 1);
$svk->checkout ('//', $copath);
chdir($copath);
mkdir('A');
mkdir('A/deep');
overwrite_file("A/foo", "foobar");

$svk->add('A');
$svk->ci(-m => 'orz');


mkdir("A/something");

is_output($svk, 'up', [-r => 0],
	  ['Syncing //(/) in '.__($corpath).' to 0.',
	   __('C   A'),
	   __('D   A/deep'),
	   __('D   A/foo'),
	   __('C   A/something'),
	   '2 conflicts found.']);

is_output($svk, 'st', [],
	  ['C   A',
	   __('C   A/something')]);

is_output($svk, 'up', [],
	  ['Syncing //(/) in '.__($corpath).' to 1.',
	   __('    A - skipped'),
	   __('    A/foo - skipped'),
	   __('    A/deep - skipped'),
]);

is_output($svk, 'st', ['A'],
	  [map {__($_) }
	   '!   A/deep',
	   '!   A/foo',
	   'C   A/something',
	   'C   A']);

is_output($svk, 'st', ['A/something'],
	  [__('C   A/something')]);


