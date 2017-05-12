#!/usr/bin/perl -w
use strict;
use Test::More tests => 16;
use SVK::Test;
use File::Path;

# build another tree to be mirrored ourself
my ($xd, $svk) = build_test();
our $output;
my $tree = create_basic_tree ($xd, '//');

my ($copath, $corpath) = get_copath ('switch');

is_output_like ($svk, 'switch', [], qr'SYNOPSIS');

$svk->cp ('-r1', '-m', 'copy', '//A', '//A-branch');
$svk->checkout ('//A-branch', $copath);

is_output_like ($svk, 'switch', ['//A-branch', '.', 'foo'], qr'SYNOPSIS');
overwrite_file ("$copath/Q/qu", "first line in qu\nlocally modified on branch\n2nd line in qu\n");

#$svk->switch ('-C', '//A');
is_output ($svk, 'switch', ['//A', $copath],
	   ["Syncing //A-branch(/A-branch) in $corpath to 3.",
	    map __($_),
	    "D   $copath/P"]);

ok ($xd->{checkout}->get ($corpath)->{depotpath} eq  '//A', 'switched');
is_file_content ("$copath/Q/qu", "first line in qu\nlocally modified on branch\n2nd line in qu\n");
chdir ($copath);
$svk->rm ('be');
$svk->commit (-m => 'remove be', 'be');

is_output ($svk, 'switch', ['//A-branch'],
	   ["Syncing //A(/A) in $corpath to 4.",
	    map __($_),
	    'A   P',
	    'A   P/pe',
	    'A   be',
	   ]);

is_output ($svk, 'switch', ['//A-branch', 'P'],
	   ['Can only switch checkout root.']);

is_output ($svk, 'switch', ['//A-branch-sdnfosa'],
	   ['Path //A-branch-sdnfosa does not exist.']);

$svk->mv (-m => 'mv', '//A-branch' => '//A-branch-renamed');

is_output ($svk, 'switch', ['//A-branch-renamed'],
	   ["Syncing //A-branch(/A-branch) in $corpath to 5."]);
is_output ($svk, 'switch', ['--detach'],
	   [__("Checkout path '$corpath' detached.")]);
chdir ('..');
rmtree [$corpath];
$svk->co ('//A-branch-renamed/P', $corpath);

is_output ($svk, 'cp', [-m => 'another branch', '//A-branch-renamed', '//A-branch-new'],
	   ['Committed revision 6.']);
is_output ($svk, 'switch', ['//A-branch-new/P', $corpath],
	   ["Syncing //A-branch-renamed/P(/A-branch-renamed/P) in $corpath to 6."]);
is_output ($svk, 'st', [$corpath], []);

$svk->rm(-m => 'kill it', '//A-branch-renamed');
is_output ($svk, 'switch', ['//A-branch-renamed/P', $corpath],
	   ["Path //A-branch-renamed/P does not exist."]);
is_output ($svk, 'switch', ['//A-branch-renamed/P@6', $corpath],
	   ["Syncing //A-branch-new/P(/A-branch-new/P) in $corpath to 6."]);

is_output ($svk, 'switch', [-r => 4, '//A-branch/P', $corpath],
	   ["Syncing //A-branch-renamed/P(/A-branch-renamed/P) in $corpath to 4."]);

