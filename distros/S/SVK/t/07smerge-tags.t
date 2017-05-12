#!/usr/bin/perl -w
use Test::More tests => 3;
use strict;
use File::Path;
use Cwd;
use SVK::Test;

my ($xd, $svk) = build_test();
our $output;
my ($copath, $corpath) = get_copath();
$svk->mkdir ('-m', 'trunk', '//trunk');
$svk->cp ('-m', 'branch', '//trunk', '//branch');
my $tree = create_basic_tree ($xd, '//trunk');
$svk->cp ('-m', 'tag1', '//trunk', '//tag1');

is_output($svk, 'sm', ['-m', 'merge tag1 to branch', '//tag1', '//branch'],
	  ['Auto-merging (0, 5) /tag1 to /branch (base /trunk:1).',
	   'A   A',
	   'A   A/Q',
	   'A   A/Q/qu',
	   'A   A/Q/qz',
	   'A   A/be',
	   'A   B',
	   'A   B/S',
	   'A   B/S/P',
	   'A   B/S/P/pe',
	   'A   B/S/Q',
	   'A   B/S/Q/qu',
	   'A   B/S/Q/qz',
	   'A   B/S/be',
	   'A   B/fe',
	   'A   me',
	   'A   C',
	   'A   C/R',
	   'A   D',
	   'A   D/de',
	   qr'New merge ticket: .*:/tag1:5',
	   qr'New merge ticket: .*:/trunk:4',
	   'Committed revision 6.'
	  ]);

$svk->checkout ('//trunk', $copath);
chdir($copath);

overwrite_file('new-in-trunk', 'new file on trunk');
$svk->add('new-in-trunk');
$svk->ci(-m => 'new file');

$svk->cp ('-m', 'tag2', '//trunk', '//tag2');

is_output($svk, 'sm', ['-m', 'merge tag2 to branch', '//tag2', '//branch'],
	  ['Auto-merging (0, 8) /tag2 to /branch (base /trunk:4).',
	   'A   new-in-trunk',
	   qr'New merge ticket: .*:/tag2:8',
	   qr'New merge ticket: .*:/trunk:7',
	   'Committed revision 9.'
	  ]);

is_output($svk, 'sm', ['-m', 'merge trunk to branch', '//trunk', '//branch'],
	  ['Auto-merging (7, 7) /trunk to /branch (base /trunk:7).',
	   'Empty merge.']);
