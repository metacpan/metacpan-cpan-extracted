#!/usr/bin/perl -w
use strict;
use SVK::Test;
plan tests => 1;
our $output;

# build another tree to be mirrored ourself
my ($xd, $svk) = build_test();

my $tree = create_basic_tree ($xd, '//');

my ($copath, $corpath) = get_copath ('update-gone');

$svk->checkout ('//A', $copath);

$svk->rm('//A', -m => 'gone');

is_output($svk, 'update', [$copath],
	 ['Path //A no longer exists.']);
