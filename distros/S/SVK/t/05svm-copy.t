#!usr/bin/perl -w
use strict;
use Test::More;
use SVK::Test;
plan tests => 2;
our ($output, $answer);
# build another tree to be mirrored ourself
my ($xd, $svk) = build_test('test');
$svk->mkdir (-m => 'trunk', '/test/trunk');
my $tree = create_basic_tree ($xd, '/test/trunk');

$svk->copy (-pm => 'local', '/test/trunk' => '/test/local');

$svk->copy (-pm => 'here', '/test/trunk' => '/test/branches/hate');
$svk->copy (-pm => 'here', '/test/trunk' => '/test/branches/hate2');

my ($srepospath, $spath, $srepos) =$xd->find_repos ('/test/trunk', 1);
my $uri = uri($srepospath);

$svk->mirror ('//m-trunk', $uri.'/trunk');
$svk->sync ('-a');

$svk->mirror ('//m-branches', $uri.'/branches');
$svk->sync ('-a');

TODO: {
local $TODO = "replay-based sync doesn't support this yet";
is_ancestor ($svk, '//m-branches/hate',
	     '/m-trunk', 4);
}

TODO: {
local $TODO = 'mirror anchor being initialized with copy';
$svk->mirror ('//m-local', $uri.'/local');
$svk->sync ('-a');
is_ancestor ($svk, '//m-local',
	     '/m-trunk', 4);
}

# DTRT when remote copy source is also something we have mirror locally.
# need resolver for remote copy too.

1;
