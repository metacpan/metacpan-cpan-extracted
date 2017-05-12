#!/usr/bin/perl -w
use strict;
use Test::More;
use SVK::Test;
eval { require SVN::Mirror; 1 } or plan skip_all => 'require SVN::Mirror';
plan tests => 3;

my ($xd, $svk) = build_test('test');

our $output;

my $tree = create_basic_tree ($xd, '/test/');

my ($copath, $corpath) = get_copath();

$svk->checkout ('/test/', $copath);

$svk->rm("$copath/A");

$svk->mkdir("$copath/A");

is_output($svk, ci => [-m => 'replace a directory without history', $copath],
          ["Committed revision 3."]);


my ($srepospath, $spath, $srepos) = $xd->find_repos ('/test/', 1);
my $uri = uri($srepospath.($spath eq '/' ? '' : $spath));

is_output($svk, mirror => ['//m', $uri],
          ["Mirror initialized.  Run svk sync //m to start mirroring."]);

is_output($svk, 'sync', ['//m'],
	  ["Syncing $uri",
	   'Retrieving log information from 1 to 3',
	   'Committed revision 2 from revision 1.',
	   'Committed revision 3 from revision 2.',
           'Committed revision 4 from revision 3.']);
