#!/usr/bin/perl -w
use strict;

use SVK::Test;
plan tests => 22;
our $output;

# build another tree to be mirrored ourself
my ($xd, $svk) = build_test('test');
$svk->mkdir('-pm' => 'trunk', '/test/project/trunk');
my $tree = create_basic_tree ($xd, '/test/project/trunk');
my ($copath, $corpath) = get_copath ('view-mirror');

$svk->cp(-m => "Create $_", '/test/project/trunk/A' => "/test/project/trunk/$_")
    for 'E'..'Z';

$svk->ps ('-m', 'my view', 'svk:view:myview',
	  '&:/project/trunk
 -*
 s   S
 v   V
 k   K
', '/test/project/trunk');
is_output($svk, 'ls', ['/test/^project/trunk/myview'],
	  ['k/', 's/', 'v/']);

my ($srepospath, $spath, $srepos) =$xd->find_repos('/test/project', 1);
my $suuid = $srepos->fs->get_uuid;
my $uri = uri($srepospath);

$svk->mi('//prj', "$uri/project");
$svk->sync('//prj');

is_output($svk, 'ls', ['//^prj/trunk/myview'],
	  ['k/', 's/', 'v/']);

is_output($svk, 'co', ['//^prj/trunk/myview', $copath],
	  ['Syncing //prj/trunk(/prj/trunk) in '.__($corpath).' to 27.',
	   map { __($_) }
	   (map {
	     ("A   $copath/$_",
	      "A   $copath/$_/Q",
	      "A   $copath/$_/Q/qu",
	      "A   $copath/$_/Q/qz",
	      "A   $copath/$_/be") } qw(s v k)),
	   " U  $copath",
	  ]);

is_output($svk, 'rm', ["$copath/k/Q/qu"],
	  [__("D   $copath/k/Q/qu")]);

is_output($svk, 'ci', [-m => 'kill Q', "$copath/k/Q"],
	  ['Commit into mirrored path: merging back directly.',
	   "Merging back to mirror source $uri/project.",
	   'Merge back committed as revision 27.',
	   "Syncing $uri/project",
	   'Retrieving log information from 27 to 27',
	   'Committed revision 28 from revision 27.']);

is_output($svk, 'st', [$copath], []);

is_output($svk, 'up', [$copath],
	  ['Syncing //^prj/trunk/myview@27(/prj/trunk) in '.__($corpath).' to 28.']);
$svk->ps ('-m', 'my local view', 'svk:view:viewA',
	  '/prj/trunk
 -*
 s   S
 v   V
 k   K
', '//');

is_output($svk, 'switch', ["//^viewA", $copath],
	  ['Syncing //^prj/trunk/myview@28(/prj/trunk) in '.__($corpath).' to 29.']);
is_output($svk, 'rm', ["$copath/k/Q/qz"],
	  [__("D   $copath/k/Q/qz")]);

is_output($svk, 'ci', [-m => 'kill Q', "$copath/k/Q"],
	  ['Commit into mirrored path: merging back directly.',
	   "Merging back to mirror source $uri/project.",
	   'Merge back committed as revision 28.',
	   "Syncing $uri/project",
	   'Retrieving log information from 28 to 28',
	   'Committed revision 30 from revision 28.']);

$svk->ps ('-m', 'swap V & K', 'svk:view:viewA',
	  '/prj/trunk
 -*
 s   S
 v   K
 k   V
', '//');

is_output($svk, 'up', [$copath],
	  ['Syncing //^viewA@29(/prj/trunk) in '.__($corpath).' to 31.',
	   map { __($_) }
	   "D   $copath/v/Q/qu",
	   "D   $copath/v/Q/qz",
	   "A   $copath/k/Q/qu",
	   "A   $copath/k/Q/qz"]);

append_file("$copath/k/Q/qu", "commit from view/K");

is_output($svk, 'ci', [-m => 'foo', $copath],
	  ['Commit into mirrored path: merging back directly.',
	   "Merging back to mirror source $uri/project.",
	   'Merge back committed as revision 29.',
	   "Syncing $uri/project",
	   'Retrieving log information from 29 to 29',
	   'Committed revision 32 from revision 29.']);

append_file("$copath/v/be", "commit from view/V");

is_output($svk, 'ci', [-m => 'modify V', $copath],
	  ['Commit into mirrored path: merging back directly.',
	   "Merging back to mirror source $uri/project.",
	   'Merge back committed as revision 30.',
	   "Syncing $uri/project",
	   'Retrieving log information from 30 to 30',
	   'Committed revision 33 from revision 30.']);

$svk->cp(-m => 'make a branch', '//prj/trunk', '//local');

$svk->ps ('-m', 'use local K for V', 'svk:view:viewA',
	  '/prj/trunk
 -*
 s   S
 v   //local/K
 k   V
', '//');

is_output($svk, 'up', [$copath],
	  ['Syncing //^viewA@31(/prj/trunk) in '.__($corpath).' to 35.']);

append_file("$copath/v/be", "local\n");

append_file("$copath/s/be", "mirrored\n");
#$svk->diff($copath);

is_output($svk, 'ci', [-m => 'booo', $copath],
	  ["Can't commit a view with changes in multiple mirror sources."]);

is_output($svk, 'ci', [-m => 'booo', "$copath/s/be"],
	  ['Commit into mirrored path: merging back directly.',
	   "Merging back to mirror source $uri/project.",
	   'Merge back committed as revision 31.',
	   "Syncing $uri/project",
	   'Retrieving log information from 31 to 31',
	   'Committed revision 36 from revision 31.',
	  ]);

is_output($svk, 'st', [$copath],
	  [__("M   $copath/v/be")]);

TODO: {
local $TODO = 'fix _commit_callback wrapper';
is_output($svk, 'ci', [-m => 'should be on local', $copath],
	  ['Committed revision 37.']);
}

is_output($svk, 'st', [$copath], []);

is_output($svk, 'mv', ["$copath/v/be", "$copath/v/be2"],
	  [__("A   $copath/v/be2"),
	   __("D   $copath/v/be")]);
TODO: {
local $TODO = 'checkout after mv is broken';
is_output($svk, 'st', [$copath],
	  [__("A + $copath/v/be2"),
	   __("D   $copath/v/be")]);

is_output($svk, 'ci', [$copath], ['Committed revision 38.']);

}
