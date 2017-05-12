#!/usr/bin/perl -w
use strict;
use SVK::Test;
plan tests => 30;
our $output;

# build another tree to be mirrored ourself
my ($xd, $svk) = build_test();
$svk->mkdir('-m' => 'trunk', '//trunk');
my $tree = create_basic_tree ($xd, '//trunk');
my ($copath, $corpath) = get_copath ('view');

$svk->ps ('-m', 'my view', 'svk:view:myview',
	  '/trunk
 -B
 -A
#  AQ/Q/qz /trunk/A/Q/qz
  BSP  /trunk/B/S/P
', '//trunk');
is_output($svk, 'ls', ['//^trunk/myview'],
	  ['BSP/', 'C/', 'D/', 'me']);

is_output($svk, 'checkout', ['//^trunk/myview', $copath],
	  ['Syncing //trunk(/trunk) in '.__($corpath)." to 4.",
	   map { __($_) } "A   $copath/me",
	   "A   $copath/C",
	   "A   $copath/C/R",
	   "A   $copath/D",
	   "A   $copath/D/de",
	   "A   $copath/BSP",
	   "A   $copath/BSP/pe",
	   " U  $copath"]);

TODO: {
local $TODO = 'intermediate directory for A/Q/qz reviving map.';
ok (-d "$copath/AQ/Q");
}
ok (!-e "$copath/A/Q/qu");
ok (-e "$copath/BSP");

is_output ($svk, 'status', [$copath], []);
append_file ("$copath/BSP/pe", "foobar\n");
is_output ($svk, 'st', [$copath],
	   [__"M   $copath/BSP/pe"]);

overwrite_file ("$copath/BSP/newfile", "foobar\n");
is_output($svk, 'add', ["$copath/BSP/newfile"],
	  [__"A   $copath/BSP/newfile"]);

is_output($svk, 'rm', ["$copath/D"],
	  [map {__($_)}
	   "D   $copath/D",
	   "D   $copath/D/de"]);

is_output($svk, 'st', [$copath],
	  [map {__($_)}
	   "M   $copath/BSP/pe",
	   "A   $copath/BSP/newfile",
	   "D   $copath/D",
	   "D   $copath/D/de",
	  ]);
is_output ($svk, 'revert', ['-R', $copath],
	   [__("Reverted $copath/BSP/pe"),
	    __("Reverted $copath/BSP/newfile"),
	    __("Reverted $copath/D"),
	    __("Reverted $copath/D/de")]);

$svk->add ("$copath/BSP/newfile");
append_file ("$copath/BSP/pe", "foobar\n");

is_output($svk, 'commit', ['-m', 'commit from view', $copath],
	  ['Committed revision 5.']);

is_output($svk, 'st', [$copath], []);

is_output($svk, 'up', [$copath],
	  ['Syncing //^trunk/myview@4(/trunk) in '.__($corpath)." to 5."]);

$svk->diff('-r4:5', '//');

rmtree [$copath];

$svk->checkout ('//trunk', $copath);

ok(-e "$copath/B/S/P/newfile", 'file created via view commit');

is_output($svk, 'switch', ['//^trunk/myview', $copath],
	  [ "Syncing //trunk(/trunk) in $corpath to 5.",
	    map { __($_) }
	    "A   $copath/BSP",
	    "A   $copath/BSP/pe",
	    "A   $copath/BSP/newfile",
	    "D   $copath/A",
	    "D   $copath/B"]);

is_output($svk, 'up', ['-r3', "$copath/BSP"],
	  ['Syncing //^trunk/myview@5(/trunk/BSP) in '.__($corpath."/BSP").' to 3.',
	   __("U   $copath/BSP/pe"),
	   __("D   $copath/BSP/newfile")]);

is_output($svk, 'up', [$copath],
	  ['Syncing //^trunk/myview@5(/trunk) in '.__($corpath).' to 5.',
	   __("U   $copath/BSP/pe"),
	   __("A   $copath/BSP/newfile")]);

is_output($svk, 'up', [-r2 => "$copath/BSP"],
	  ['Syncing //^trunk/myview@5(/trunk) in '.__($corpath).' to 2.',
	   __("D   $copath/BSP")]);

is_output($svk, 'st', [$copath], []);

is_output($svk, 'up', [$copath],
	  ['Syncing //^trunk/myview@5(/trunk) in '.__($corpath).' to 5.',
	   __("A   $copath/BSP"),
	   __("A   $copath/BSP/pe"),
	   __("A   $copath/BSP/newfile")]);

is_output($svk, 'up', ['-r4', "$copath/BSP"],
	  ['Syncing //^trunk/myview@5(/trunk/BSP) in '.__($corpath."/BSP").' to 4.',
	   __("U   $copath/BSP/pe"),
	   __("D   $copath/BSP/newfile")]);

$svk->ps ('-m', 'A view', 'svk:view:view-A',
	  '/trunk/A
 -Q
 qz   Q/qz
 BSP  /trunk/B/S/P
', '//trunk/A');

is_output($svk, 'ls', ['//^trunk/A/view-A'],
	  ['BSP/', 'be', 'qz']);

$svk->ps ('-m', 'A view', 'svk:view:view-A',
	  '/trunk/A
 -*
 X    Q
', '//trunk/A');
rmtree [$copath];

is_output($svk, 'co', ['//^trunk/A/view-A', $copath],
	  ['Syncing //trunk/A(/trunk/A) in '.__($corpath).' to 7.',
__("A   $copath/X"),
__("A   $copath/X/qu"),
__("A   $copath/X/qz"),
__(" U  $copath")
]);

is_output($svk, 'rm', ["$copath/X/qz"],
	  [__("D   $copath/X/qz")]);

is_output($svk, 'ci', [-m => 'foo', $copath],
	  ['Committed revision 8.']);

overwrite_file("$copath/X/orz", "orz\n");
is_output($svk, 'add', ["$copath/X/orz"],
	  [__("A   $copath/X/orz")]);
is_output($svk, 'rm', ["$copath/X/qu"],
	  [__("D   $copath/X/qu")]);

is_output($svk, 'ci', [-m => 'foo', $copath],
	  ['Committed revision 9.']);

is_output($svk, 'up', ["$copath"],
	  ['Syncing //^trunk/A/view-A@7(/trunk/A) in '.__($corpath).' to 9.']);

TODO: {
local $TODO = 'blame in view.';
$svk->blame("$copath/X/orz");
#warn $output;

$svk->blame('//^trunk/A/view-A/X/orz@7');
#warn $output;
}
