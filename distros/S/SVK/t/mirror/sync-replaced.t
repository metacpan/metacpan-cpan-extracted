#!/usr/bin/perl -w
use strict;
use Test::More;
use SVK::Test;
eval { require SVN::Mirror; 1 } or plan skip_all => 'require SVN::Mirror';
plan tests => 7;

my ($xd, $svk) = build_test('test');

our $output;

my $tree = create_basic_tree ($xd, '/test/');

my ($copath, $corpath) = get_copath();

$svk->checkout ('/test/', $copath);

append_file("$copath/A/Q/qu", "orz\n");
$svk->ci(-m => 'change qu', $copath);

$svk->rm("$copath/A");
$svk->cp('/test/A@2', "$copath/A");
append_file("$copath/A/Q/qu", "this is a different change\n");
#$ENV{SVKDEBUG} = 'SVK::Editor::Status';

$svk->st("$copath/A");

$svk->ci(-m => 'replace A with older A, with different change to qu', $copath);

my ($srepospath, $spath, $srepos) = $xd->find_repos ('/test/', 1);
my $uri = uri($srepospath.($spath eq '/' ? '' : $spath));

$svk->mirror ('//m', $uri);
is_output($svk, 'sync', ['--to', 3, '//m'],
	  ["Syncing $uri",
	   'Retrieving log information from 1 to 3',
	   'Committed revision 2 from revision 1.',
	   'Committed revision 3 from revision 2.',
	   'Committed revision 4 from revision 3.']);

is_output($svk, 'sync', ['//m'],
	  ["Syncing $uri",
	   'Retrieving log information from 4 to 4',
	   'Committed revision 5 from revision 4.']);

is_output($svk, 'log', [-vr5 => '//m'],
	  [qr|-+|, qr|r5 \(orig r4\)|, 'Changed paths:',
	   '  R  /m/A (from /m/A:3)',
	   '  M  /m/A/Q/qu', '', 'replace A with older A, with different change to qu', qr|-+|]);

$svk->cat('/test/A/Q/qu');
my $expected = $output;

is_output($svk, 'cat', ['//m/A/Q/qu'], [split(/\r?\n/,$expected)], 'content is the same');

$svk->cp(-m => 'b cp', '/test/B' => '/test/B.cp');
$svk->up($copath);
append_file("$copath/B.cp/fe", "modify fe");
$svk->ci(-m => 'modify fe in B.cp', $copath );

$svk->rm("$copath/B/fe");
$svk->cp('/test/B.cp/fe', "$copath/B/fe"); # replace with a related file
append_file("$copath/B/fe", "orz\n");
$svk->rm("$copath/B/S/be");
$svk->cp('/test/B.cp/fe', "$copath/B/S/be"); # replace with a unrelated file
append_file("$copath/B/S/be", "orz\n");
$svk->cp('/test/A/Q/qz', "$copath/B/fnord");
$svk->add("$copath/B/fnord");
$svk->ci(-m => 'replace a file in B from A', $copath );

$svk->rm(-m => 'remove mirror', '//m');

$svk->mirror('//m', "$uri/B");

sleep 1; # so svn:date is definitely different if not mirrored

is_output($svk, 'sync', ['//m'],
	  ["Syncing $uri/B",
	   'Retrieving log information from 1 to 7',
	   'Committed revision 9 from revision 1.',
	   'Committed revision 10 from revision 2.',
	   'Committed revision 11 from revision 7.']);

$svk->pg('--revprop', '-r1', 'svn:author', '/test/');
$expected = $output;
is_output($svk, 'pg', ['--revprop', '-r9', 'svn:author', '//m'],
         [split(/\n/, $expected)],
          'author is mirrored');

$svk->pg('--revprop', '-r1', 'svn:date', '/test/');
$expected = $output;
is_output($svk, 'pg', ['--revprop', '-r9', 'svn:date', '//m'],
         [split(/\n/, $expected)],
          'date is mirrored');
