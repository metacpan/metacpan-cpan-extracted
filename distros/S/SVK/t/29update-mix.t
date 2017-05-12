#!/usr/bin/perl -w
use strict;
use SVK::Test;
plan tests => 2;

our $output;
my ($xd, $svk) = build_test();
my ($copath, $corpath) = get_copath ('update-mix1');
my ($scopath, $scorpath) = get_copath ('update-mix2');

my ($repospath, undef, $repos) = $xd->find_repos ('//', 1);

$svk->mkdir(-pm => 'deep tree', '//work/trunk/deep/test' );
$svk->mkdir(-pm => 'deep tree', '//work/trunk/another/tree' );
create_basic_tree ($xd, '//work/trunk/deep/test');
create_basic_tree ($xd, '//work/trunk/another/tree');

$svk->checkout('//work/trunk', $copath);
$svk->checkout('//work/trunk', $scopath);


append_file("$copath/deep/test/A/be", "fnord\n");
$svk->ci(-m => 'blah', $copath);

append_file("$scopath/deep/test/A/Q/qu", "fnord\n");
$svk->ci(-m => 'blah', $scopath);

append_file("$copath/deep/test/B/fe", "fnord\n");
$svk->ci(-m => 'blah', $copath);

is_output($svk, 'up', ["$scopath/deep/test"],
	  ['Syncing //work/trunk/deep/test(/work/trunk/deep/test) in '.
	   __("$scorpath/deep/test").' to 9.',
	   map {__($_)}
	   "U   $scopath/deep/test/A/be",
	   "U   $scopath/deep/test/B/fe",
	  ]);

$svk->admin('rmcache');
is_output($svk, 'st', ["$scopath/deep/test"], []);
