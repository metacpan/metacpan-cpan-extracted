#!/usr/bin/perl -w
use strict;
use SVK::Test;
plan tests => 4;
our $output;

my ($xd, $svk) = build_test('test','server');

waste_rev ($svk, '/test/F') for 1..100;
waste_rev ($svk, '/server/F') for 1..20;
waste_rev ($svk, '//F') for 1..30;

$svk->mkdir (-m => 'trunk', '/test/trunk');
my $tree = create_basic_tree ($xd, '/test/trunk');

my ($srepospath, $spath, $srepos) = $xd->find_repos ('/test/trunk', 1);
my ($repospath, $path, $repos) = $xd->find_repos ('/server/trunk', 1);

$svk->mirror ('/server/trunk', uri($srepospath).'/trunk');
is_output ($svk, 'sync', ['/server/trunk'],
	   ["Syncing ".uri($srepospath).'/trunk',
	    'Retrieving log information from 1 to 203',
	    'Committed revision 42 from revision 201.',
	    'Committed revision 43 from revision 202.',
	    'Committed revision 44 from revision 203.']);

TODO: {
local $TODO = 'relayed mirror';

$svk->mirror ('//trunk', uri($repospath).'/trunk');
is_output ($svk, 'sync', ['//trunk'],
	   ["Syncing ".uri($srepospath)."/trunk via ".uri($repospath)."/trunk",
	    'Retrieving log information from 1 to 44',
	    'Committed revision 62 from revision 41.',
	    'Committed revision 63 from revision 42.',
	    'Committed revision 64 from revision 43.',
	    'Committed revision 65 from revision 44.']);

$svk->cp (-m => 'local', '//trunk@64', '//local');
my $suuid = $srepos->fs->get_uuid;
is_output_like ($svk, 'sm', [-m => 'merge down', -t => '//local'],
		qr{New merge ticket: $suuid:/trunk:203});
is_output_like ($svk, 'info', ['//local'],
		qr'Merged From: /trunk, Rev. 65');
}
