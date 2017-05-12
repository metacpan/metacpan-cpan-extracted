#!/usr/bin/perl -w
use Test::More tests => 26;
use strict;
use File::Path;
use Cwd;
use SVK::Test;


my ($xd, $svk) = build_test();
our $output;
my ($copath, $corpath) = get_copath();
$svk->mkdir ('-m', 'trunk', '//trunk');
my $tree = create_basic_tree ($xd, '//trunk');
$svk->cp ('-m', 'branch', '//trunk', '//local');

$svk->checkout ('//trunk', $copath);
chdir($copath);
# simple case
$svk->cp('A' => 'A-cp');
$svk->ci(-m => 'copy A');

is_output($svk, 'pull', ['//local'],
	  ['Auto-merging (3, 5) /trunk to /local (base /trunk:3).',
	   'A + A-cp',
	   qr'New merge ticket: .*:/trunk:5',
	   'Committed revision 6.'
	  ]);

is_ancestor($svk, '//local/A-cp', '/local/A', 4, '/trunk/A', 3);

# partially expand, still retain the history structure
$svk->mkdir('//trunk/A/new', -m => 'new dir');
$svk->cp('//trunk/A' => '//trunk/A-cp-again', -m => 'more');

$svk->pull('//local');
is_ancestor($svk, '//local/A-cp-again', '/local/A', 4, '/trunk/A', 3);

$svk->cp('//trunk/A-cp-again' => '//trunk/A-cp-more', -m => 'more');

is_output($svk, 'pull', ['//local'],
	  ['Auto-merging (8, 10) /trunk to /local (base /trunk:8).',
	   'A + A-cp-more',
	   qr'New merge ticket: .*:/trunk:10',
	   'Committed revision 11.']);

is_ancestor($svk, '//local/A-cp-more',
	    '/local/A-cp-again', 9, '/local/A', 4, '/trunk/A', 3);
$svk->up;

# replace with history.  this is very tricky, because we have to use
# ignore_ancestry in dir_delta, and this makes the replace an
# modification, rather than an add.

$svk->rm('A/be');
$svk->cp('A/Q/qu', 'A/be');
$svk->ci(-m => 'replace A/be');

is_output($svk, 'pull', ['//local'],
	  ['Auto-merging (10, 12) /trunk to /local (base /trunk:10).',
	   'R + A/be',
	   qr'New merge ticket: .*:/trunk:12',
	   'Committed revision 13.']);

# note that it's copied from 6, not 4.  should be normalised when
# trying to copy
is_ancestor($svk, '//local/A/be',
	    '/local/A/Q/qu', 4,
	    '/trunk/A/Q/qu', 2);


$svk->mv('A/Q/qu', 'A/quz');
$svk->ci(-m => 'move A/Q/qu');

is_output($svk, 'pull', ['//local'],
	  ['Auto-merging (12, 14) /trunk to /local (base /trunk:12).',
	   'A + A/quz',
	   'D   A/Q/qu',
	   qr'New merge ticket: .*:/trunk:14',
	   'Committed revision 15.']);

is_ancestor($svk, '//local/A/quz',
	    '/local/A/Q/qu', 4,
	    '/trunk/A/Q/qu', 2);

# copy and modify
$svk->cp('A/quz', 'A/quz-mod');
append_file('A/quz-mod', "modified after copy\n");

$svk->ci(-m => 'copy file with modification');

is_output($svk, 'pull', ['//local'],
	  ['Auto-merging (14, 16) /trunk to /local (base /trunk:14).',
	   'A + A/quz-mod',
	   qr'New merge ticket: .*:/trunk:16',
	   'Committed revision 17.']);

is_file_content('A/quz-mod',
		"first line in qu\n2nd line in qu\nmodified after copy\n");

# copy directory and modify
$svk->cp('B', 'B-mod');

append_file('B-mod/fe', "modified after copy\n");
append_file('B-mod/S/P/pe', "modified after copy\n");
overwrite_file('B-mod/S/new', "new file\n");
$svk->add('B-mod/S/new');
$svk->ci(-m => 'copy file with modification');

is_output($svk, 'pull', ['//local'],
	  ['Auto-merging (16, 18) /trunk to /local (base /trunk:16).',
	   'A + B-mod',
	   'U   B-mod/S/P/pe',
	   'A   B-mod/S/new',
	   'U   B-mod/fe',
	   qr'New merge ticket: .*:/trunk:18',
	   'Committed revision 19.']);

is_output ($svk, 'sw', ['//local'],
	   ["Syncing //trunk(/trunk) in $corpath to 19."],
	   'should be no differences.');

$svk->mv('//trunk/B', '//trunk/B-tmp', -m => 'B -> tmp');
$svk->mv('//trunk/A', '//trunk/B', -m => 'A -> B');
$svk->mv('//trunk/B-tmp', '//trunk/A', -m => 'B-tmp -> A');

is_output($svk, 'pull', ['//local'],
	  ['Auto-merging (18, 22) /trunk to /local (base /trunk:18).',
	   'R + A',
	   'R + B',
	   qr'New merge ticket: .*:/trunk:22',
	   'Committed revision 23.']);

$svk->cp('//trunk' => '//local-new', -m => 'new branch');
$svk->cp('//trunk/B' => '//trunk/B-earlytrunk',
	 -m => 'copy to earlyxtrunk');
$svk->sw('//local-new');
$svk->cp('B' => 'B-fromlocal');
$svk->ci(-m => 'a copy at local');

is_output($svk, 'push', [],
	  ['Auto-merging (0, 26) /local-new to /trunk (base /trunk:22).',
	   '===> Auto-merging (0, 24) /local-new to /trunk (base /trunk:22).',
	   'Empty merge.',
	   '===> Auto-merging (24, 26) /local-new to /trunk (base /trunk:22).',
	   'A + B-fromlocal',
	   qr'New merge ticket: .*:/local-new:26',
	   'Committed revision 27.']);

$svk->cp('//trunk/B' => '//trunk/B-orztrunk',
	 -m => 'copy to orztrunk');
$svk->cp('//trunk/B-fromlocal' => '//trunk/B-totrunk',
	 -m => 'copy to trunk new directory');

is_output($svk, 'pull', ['//local-new'],
	  ['Auto-merging (22, 29) /trunk to /local-new (base /local-new:26).',
	   'A + B-earlytrunk',
	   'A + B-totrunk',
	   'A + B-orztrunk',
	   qr'New merge ticket: .*:/trunk:29',
	   'Committed revision 30.',
	  ]);

is_ancestor($svk, '//local-new/B-totrunk',
	    '/local-new/B-fromlocal', 26,
	    '/local-new/B', 24,
	    '/trunk/B', 21,
	    '/trunk/A', 16);
is_ancestor($svk, '//local-new/B-orztrunk',
	    '/local-new/B', 24,
	    '/trunk/B', 21,
	    '/trunk/A', 16);


# a bunch of modification and then merge back
$svk->cp ('-m', 'branch', '//trunk@3', '//trunk-3');
$svk->cp ('-m', 'branch', '//trunk-3', '//local-many');

$svk->sw ('//trunk-3');
append_file('D/de', 'modify this on trunk');
$svk->ci(-m => 'modify D/de, which is to be moved from //local-many');

$svk->sw('//local-many');
$svk->cp('B/S' => 'b-s');
$svk->ci(-m => 'rename B/S');

overwrite_file('D/de', "modify on D/de\nfile de added later\n");
$svk->ci(-m => 'change de');

$svk->cp('D/de' => 'b-s/de');
$svk->ci(-m => 'cp de under b-s');

$svk->mv('D/de' => 'B/de');
$svk->ci(-m => 'move de to B');

overwrite_file('B/de', "modify on D/de\nmodify on B/de\nfile de added later\n");
$svk->ci(-m => 'change de');

overwrite_file('new-in-local', 'new file on local');
$svk->add('new-in-local');
$svk->ci(-m => 'new file');

$svk->mv('new-in-local' => 'D');
$svk->ci(-m => 'move new file to D');

$ENV{SVKRESOLVE} = 't';
#our $answer = ['t'];

is_output($svk, 'push', ['-l'],
	  ['Auto-merging (0, 40) /local-many to /trunk-3 (base /trunk-3:31).',
	   'G + B/de',
	   'A + b-s',
	   'G + b-s/de',
	   'A   D/new-in-local',
	   'D   D/de',
	   qr'New merge ticket: .*:/local-many:40',
	   qr'New merge ticket: .*:/trunk:3',
	   'Committed revision 41.']);
is_output($svk, 'cat', ['//trunk-3/B/de'],
	  ['modify on D/de',
	   'modify on B/de',
	   'file de added later',
	   'modify this on trunk']);

is_output($svk, 'diff', ['-sr40:41', '//'],
	  ['M + trunk-3/B/de',
	   'A + trunk-3/b-s',
	   'M + trunk-3/b-s/de',
	   'A   trunk-3/D/new-in-local',
	   'D   trunk-3/D/de',
	   ' M  trunk-3']);

$svk->cp(-m => 'cross branch', '//local-many/b-s', '//trunk-3/b-s-cp');

is_output($svk, 'pull', ['//local-many'],
	  ['Auto-merging (31, 42) /trunk-3 to /local-many (base /local-many:40).',
	   'U   B/de',
	   'U   b-s/de',
	   'A + b-s-cp',
	   qr'New merge ticket: .*:/trunk:3',
	   qr'New merge ticket: .*:/trunk-3:42',
	   'Committed revision 43.']);

$svk->rm('//trunk-3/B/de', -m => 'bye');
$svk->mkdir('//trunk-3/B/gotnew', -m => 'new');
$svk->mv('//trunk-3/B' => '//trunk-3/B-moved', -m => 'moved');

is_output($svk, 'pull', ['//local-many'],
	  ['Auto-merging (42, 46) /trunk-3 to /local-many (base /trunk-3:42).',
	   'A + B-moved',
	   'A   B-moved/gotnew',
	   'D   B-moved/de',
	   'D   B',
	   qr'New merge ticket: .*:/trunk-3:46',
	   'Committed revision 47.'
	  ]);
$svk->mkdir(-m => 'outside', '//outside');
$svk->cp(-m => 'outside -> trunk', '//outside' => '//trunk-3/outside');

is_output($svk, 'pull', ['//local-many'],
	  ['Auto-merging (46, 49) /trunk-3 to /local-many (base /trunk-3:46).',
	   'A + outside',
	   qr'New merge ticket: .*:/trunk-3:49',
	   'Committed revision 50.'
	  ]);

is_ancestor($svk, '//local-many/outside',
	    '/outside', 48);

$svk->cp(-m => 'a simple file copy to collide', '//trunk-3/B-moved/fe' => '//trunk-3/outside/fe');

$svk->up;

overwrite_file('outside/fe', "lala our own\n");
$svk->add('outside/fe');
$svk->commit(-m => 'ours');

$ENV{SVKRESOLVE} = 's';

is_output($svk, 'pull', ['//local-many'],
	  ['Auto-merging (49, 51) /trunk-3 to /local-many (base /trunk-3:49).',
	   'C   outside/fe',
	   qr'New merge ticket: .*:/trunk-3:51',
	   'Empty merge.',
	   '1 conflict found.']);

#$svk->up;
# check if prop change only
#$svk->diff('//trunk-3', '//local-many');
