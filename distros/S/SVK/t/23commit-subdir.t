#!/usr/bin/perl -w
use strict;
use SVK::Test;
plan tests => 2;

my ($xd, $svk) = build_test('test');

my $tree = create_basic_tree ($xd, '/test/');
my ($srepospath, $spath, $srepos) = $xd->find_repos ('/test/', 1);

my $uri = uri($srepospath);

$svk->mirror ('//remote', $uri);
$svk->sync ('//remote');
my ($copath, $corpath) = get_copath ('commit-subdir');


$svk->checkout ('//remote', $copath);
append_file ("$copath/A/be", "modified on A\n");

is_output ($svk, 'status', [$copath],
	   [__"M   $copath/A/be"]);

$svk->mkdir(-m => 'hi', '/test/B/injected');
$svk->mkdir(-m => 'hi', '/test/B/injected2');
$svk->mkdir(-m => 'hi', '/test/B/injected3');
$svk->mkdir(-m => 'hi', '/test/B/injected5');

chdir("$copath/A");

is_output ($svk, 'commit', ['-m', 'modify A'],
	   [map qr'.*',(1..4),
	    'Retrieving log information from 3 to 7',
	    'Committed revision 4 from revision 3.',
	    'Committed revision 5 from revision 4.',
	    'Committed revision 6 from revision 5.',
	    'Committed revision 7 from revision 6.',
	    'Committed revision 8 from revision 7.']);

