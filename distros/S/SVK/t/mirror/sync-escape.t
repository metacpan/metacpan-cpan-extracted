#!/usr/bin/perl -w
use strict;
use Test::More;
use SVK::Test;
#plan skip_all => 'blah';
eval { require SVN::Mirror; 1 } or plan skip_all => 'require SVN::Mirror';
plan tests => 8;

my ($xd, $svk) = build_test('test');
my ($copath, $corpath) = get_copath ('sync-escape');

our $output;

my $tree = create_basic_tree ($xd, '/test/');

$svk->mkdir(-m => 'make dir with space.', '/test/orz dir');
$svk->mkdir(-m => 'make dir with %.', '/test/orzo%2Fdir');

$svk->mkdir(-m => 'something', '/test/orzo');

$svk->cp(-m => 'cp with % .', '/test/orzo%2Fdir', '/test/orzo%2Fdir2');

$svk->co('/test/', $copath);
chdir($copath);

is_output($svk, 'rm', ['orzo%2Fdir2'],
	  ['D   orzo%2Fdir2']);
is_output($svk, 'cp', ['/test/orzo%2Fdir', 'orzo%2Fdir2'],
	  ['A   orzo%2Fdir2']);
append_file('me', 'hate');
$svk->ci(-m => 'replace');

overwrite_file("orzo%2Fdir2/filewith%2Fescape", 'blah');
$svk->add("orzo%2Fdir2/filewith%2Fescape");
$svk->cp('me' => "orzo%2Fdir2/copywith%2Fescape");
$svk->ci(-m => 'files');

$svk->rm("orzo%2Fdir2/filewith%2Fescape");
$svk->cp("orzo%2Fdir2/copywith%2Fescape" => "orzo%2Fdir2/filewith%2Fescape");
$svk->ci(-m => 'replace file');

my ($srepospath, $spath, $srepos) = $xd->find_repos ('/test/', 1);
my $uri = uri($srepospath.($spath eq '/' ? '' : $spath));

is_output($svk, mirror => ['//m', $uri],
          ["Mirror initialized.  Run svk sync //m to start mirroring."]);

is_output($svk, 'sync', [-t6 => '//m'],
	  ["Syncing $uri",
	   'Retrieving log information from 1 to 6',
	   'Committed revision 2 from revision 1.',
	   'Committed revision 3 from revision 2.',
	   'Committed revision 4 from revision 3.',
	   'Committed revision 5 from revision 4.',
	   'Committed revision 6 from revision 5.',
	   'Committed revision 7 from revision 6.']);

is_output($svk, 'sync', [-t7 => '//m'],
	  ["Syncing $uri",
	   'Retrieving log information from 7 to 7',
	   'Committed revision 8 from revision 7.']);

is_output($svk, 'sync', [-t8 => '//m'],
	  ["Syncing $uri",
	   'Retrieving log information from 8 to 8',
	   'Committed revision 9 from revision 8.']);

is_output($svk, 'sync', [-t9 => '//m'],
	  ["Syncing $uri",
	   'Retrieving log information from 9 to 9',
	   'Committed revision 10 from revision 9.']);


$svk->mkdir(-m => 'dir with space', '/test/Project Space');

is_output($svk, 'sync', [-t10 => '//m'],
	  ["Syncing $uri",
	   'Retrieving log information from 10 to 10',
	   'Committed revision 11 from revision 10.']);
