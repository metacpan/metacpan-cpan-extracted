#!/usr/bin/perl -w
use strict;
use SVK::Test;
plan tests => 1 ;

my ($xd, $svk) = build_test ();

$svk->mkdir (-m => 'init', '//trunk');
my $tree = create_basic_tree ($xd, '//trunk');

$svk->mv (-m => 'there', '//trunk' => '//trunk-foo');
$svk->mv (-m => 'and back again', '//trunk-foo' => '//trunk');

my ($copath, $corpath) = get_copath ('smerge-anchor-replace');

$svk->co ('//trunk', $copath);

append_file ("$copath/B/fe", "some changes\n");
overwrite_file ("$copath/newfile", "newfile\n");
$svk->add ("$copath/newfile");
$svk->ci (-m => 'changes after trunk moved back', $copath);

$svk->cp (-m => 'branch to local', '//trunk' => '//local');

append_file ("$copath/B/fe", "more changes\n");
append_file ("$copath/newfile", "more\n");

$svk->ci (-m => 'more changes on trunk', $copath);

my (undef, undef, $repos) = $xd->find_repos ('//trunk', 1);

my $uuid = $repos->fs->get_uuid;
is_output ($svk, 'sm', [-Ct => '//local'],
	   ['Auto-merging (6, 8) /trunk to /local (base /trunk:6).',
	    'U   B/fe',
	    'U   newfile',
	    "New merge ticket: $uuid:/trunk:8",
	    "New merge ticket: $uuid:/trunk-foo:4"]);
