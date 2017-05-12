#!/usr/bin/perl -w
use strict;
use SVK::Test;
plan tests => 14;

our ($answer, $output);
my ($xd, $svk) = build_test();
$svk->mkdir ('-m', 'init', '//V');
my $tree = create_basic_tree ($xd, '//V');

my ($copath, $corpath) = get_copath ('autovivify');
mkdir $corpath;

chdir($corpath);
$answer = '//new/A';
is_output($svk, 'copy', [-m => 'copy to current dir', '//V/A'], [
            'Committed revision 4.',
            "Syncing //new/A(/new/A) in ".__("$corpath/A to 4."),
            __("A   A/Q"),
            __("A   A/Q/qu"),
            __("A   A/Q/qz"),
            __("A   A/be"),
            ]);

is_output($svk, 'update', ["$corpath/A"], [
            "Syncing //new/A(/new/A) in ".__("$corpath/A to 4."),
            ]);

my ($xd2, $svk2) = build_test('test');
my $tree2 = create_basic_tree ($xd2, '/test/');
my ($srepospath, $spath, $srepos) = $xd2->find_repos ('/test/B', 1);
my $suuid = $srepos->fs->get_uuid;
my $uri = uri($srepospath);

is_output($svk, 'cp', ["$uri/C", "$uri/D"],
	  ["Copy destination can't be URI."]);

$answer = ['', 'C', ''];
is_output($svk, 'checkout', ["$uri/C"], [
            "New URI encountered: $uri/C/",
            "Mirror initialized.  Run svk sync //mirror/C to start mirroring.",
            "",
            "svk needs to mirror the remote repository so you can work locally.",
            "If you're mirroring a single branch, it's safe to use any of the options",
            "below.",
            "",
            "If the repository you're mirroring contains multiple branches, svk will",
            "work best if you choose to retrieve all revisions.  Choosing to start",
            "with a recent revision can result in a larger local repository and will",
            "break history-sensitive merging within the mirrored path.",
            "",
            "Synchronizing the mirror for the first time:",
            "  a        : Retrieve all revisions (default)",
            "  h        : Only the most recent revision",
            "  -count   : At most 'count' recent revisions",
            "  revision : Start from the specified revision",
            "Syncing $uri/C",
            "Retrieving log information from 1 to 2",
            "Committed revision 6 from revision 1.",
	    "Syncing //mirror/C(/mirror/C) in ".__("$corpath/C to 6."),
            __("A   C/R"),
            ]);
chdir ('C');
is_output($svk, 'cp', ["$uri/A"],
	  ["URI not allowed here: path '' is already a checkout."]);
is_output($svk, 'checkout', ["$uri/A"],
	  ["URI not allowed here: path '' is already a checkout."]);
chdir ('..');
is_output($svk, 'cp', ["$uri/C", "$uri/D", 'C'],
	  ['More than one URI found.']);

rmtree ['C'];
# unused
$answer = ['', '', ''];
is_output($svk, 'checkout', ["$uri/C"],
	  ["Syncing //mirror/C(/mirror/C) in ".__("$corpath/C to 6."),
	   __("A   C/R")]);
is_output($svk, 'update', ["$corpath/C"], [
            "Syncing //mirror/C(/mirror/C) in ".__("$corpath/C to 6.")
            ]);

rmtree ['C'];
is_output($svk, 'cp', [-m => 'local branch for C', "$uri/C"], [
            "Committed revision 7.",
	    "Syncing //C(/C) in ".__("$corpath/C to 7."),
            __("A   C/R"),
            ]);
is_ancestor ($svk, "C", '/mirror/C', 6);

$answer = 'C-hate';
is_output($svk, 'cp', [-m => 'local branch for C', "$uri/C"], [
            "Committed revision 8.",
	    "Syncing //C-hate(/C-hate) in ".__("$corpath/C-hate to 8."),
            __("A   C-hate/R"),
            ]);
is_ancestor ($svk, "C-hate", '/mirror/C', 6);

rmtree ['C'];
$answer = ['', 'C-bizzare'];
is_output($svk, 'cp', [-m => 'local branch for C', "$uri/C"],
	  [ 'Path //C already exists.',
            "Committed revision 9.",
	    "Syncing //C-bizzare(/C-bizzare) in ".__("$corpath/C-bizzare to 9."),
            __("A   C-bizzare/R"),
            ]);

