#!/usr/bin/perl -w
use strict;
use warnings;
use SVK::Test;
use Test::More tests => 1;
our ($output, $answer);

my ($xd, $svk) = build_test('test');
$svk->mkdir (-pm => 'trunk', '//trunk');
my $tree = create_basic_tree ($xd, '//trunk');

my ($srepospath, $spath, $srepos) = $xd->find_repos ('//trunk', 1);
my $uri = uri($srepospath);

$svk->mirror('/test/private', $uri);
$svk->sync('-a');

$svk->mkdir(-m => 'blah', '//fsoapf');
is_output($svk, 'cp', [-m => 'foo', '/test/private/trunk', '/test/private/trunk-foo'],
	  ["Merging back to mirror source $uri.",
	   'Merge back committed as revision 5.',
	   "Syncing $uri",
	   'Retrieving log information from 4 to 5',
	   'Committed revision 5 from revision 4.',
	   'Committed revision 6 from revision 5.']);

