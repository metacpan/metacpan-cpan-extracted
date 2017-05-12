#!/usr/bin/perl -w
use Test::More tests => 5;
use strict;
our $output;
use SVK::Test;
my ($xd, $svk) = build_test();
my ($copath, $corpath) = get_copath ('copy-escape');

# escaped chars
is_output($svk, 'mkdir', [-m => 'mkdir', -p => '//foo/blah%2Ffnord'],
	  ['Committed revision 1.']);

is_output($svk, 'cp', [-m => 'cp', '//foo/blah%2Ffnord', "//foo/baz%2Ffnord"],
	  ['Committed revision 2.']);

is_output($svk, 'ls', ['//foo'], ['baz%2Ffnord/', 'blah%2Ffnord/']);

$svk->co('//foo', $copath);
chdir($copath);

is_output($svk, 'cp', ['//foo/blah%2Ffnord', "onco%2Ffnord"],
	  ['A   onco%2Ffnord']);

is_output($svk, 'commit', ['-m' => 'commit cp'],
	  ['Committed revision 3.']);

