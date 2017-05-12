#!/usr/bin/perl -w
use strict;
use SVK::Test;
plan tests => 1;

use File::Path;
our ($output, $answer);
# build another tree to be mirrored ourself
my ($xd, $svk) = build_test('test', 'client2');
$svk->mkdir ('-m', 'init', '/test/version-A');
$svk->mkdir ('-m', 'init', '/client2/version-B');
create_basic_tree ($xd, '/test/version-A');
create_basic_tree ($xd, '/client2/version-B');

my ($copath, $corpath) = get_copath ('smerge-baseless');

$svk->checkout ('/test/version-A', $copath);
append_file ("$copath/A/be", "version A\n");
append_file ("$copath/A/Q/qu", "modified on A\n");
overwrite_file ("$copath/bzz", "version A\n");
$svk->add ("$copath/bzz");
$svk->commit ('-m', 'yo', $copath);

rmtree [$copath];

$svk->checkout ('/client2/version-B', $copath);
append_file ("$copath/A/be", "version B\n");
overwrite_file ("$copath/bzz", "version B\n");
$svk->add ("$copath/bzz");
$svk->commit ('-m', 'yo', $copath);


my ($arepospath, undef, $arepos) = $xd->find_repos ('/test/version-A', 1);
my $uuid = $arepos->fs->get_uuid;
$svk->mirror ('//version-A', uri ($arepospath).'/version-A');
my ($brepospath, undef, $brepos) = $xd->find_repos ('/client2/version-B', 1);
my $buri = uri ($brepospath).'/version-B';
$svk->mirror ('//version-B', $buri);
$svk->sync ('-a');
#$answer = 't';
is_sorted_output ($svk, 'smerge', ['-BC', '//version-A', '//version-B'],
	   ['Auto-merging (0, 6) /version-A to /version-B (base /:0).',
	    "Checking locally against mirror source $buri.",
	    'C   A/Q/qu',
	    'g   A/Q/qz',
	    'Gg  A/Q',
	    'Cg  A/be',
	    'G   A',
	    'g   B/S/P/pe',
	    'G   B/S/P',
	    'g   B/S/Q/qu',
	    'g   B/S/Q/qz',
	    'Gg  B/S/Q',
	    'gg  B/S/be',
	    'G   B/S',
	    'g   B/fe',
	    'G   B',
	    'g   me',
	    'G   C/R',
	    'G   C',
	    'g   D/de',
	    'G   D',
	    'C   bzz',
	    "New merge ticket: $uuid:/version-A:4",
	    'Empty merge.',
	    '3 conflicts found.']);
