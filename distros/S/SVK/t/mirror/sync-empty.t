#!/usr/bin/perl -w
use strict;
use Test::More;
use SVK::Test;
eval { require SVN::Mirror; 1 } or plan skip_all => 'require SVN::Mirror';
plan tests => 2;

my ($xd, $svk) = build_test('test');

our $output;

my ($srepospath, $spath, $srepos) = $xd->find_repos ('/test/A', 1);
$svk->mkdir ('-m', 'init', '/test/A');

my $uri = uri($srepospath.($spath eq '/' ? '' : $spath));

$svk->mirror ('//m', $uri);
is_output($svk, 'sync', ['//m'],
	  ["Syncing $uri",
	   'Retrieving log information from 1 to 1',
	   'Committed revision 2 from revision 1.']);

is_output($svk, 'sync', ['//m'],
	  ["Syncing $uri"]);
