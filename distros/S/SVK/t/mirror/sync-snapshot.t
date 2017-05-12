#!/usr/bin/perl -w
use strict;
use Test::More tests => 6;
use SVK::Test;
use SVN::Ra;
use SVK::Mirror::Backend::SVNSync;

my ($xd, $svk) = build_test('test');
my $depot = $xd->find_depot('test');

my ($copath, $corpath) = get_copath();
our $output;

my ($srepospath, $spath, $srepos) = $xd->find_repos ('/test/', 1);
my $tree = create_basic_tree($xd, '/test/');
$svk->rm(-m => 'kill B', '/test/B');

my $uri = uri($srepospath.($spath eq '/' ? '' : $spath));

is_output($svk, mirror => ['//trunk', $uri],
          ["Mirror initialized.  Run svk sync //trunk to start mirroring."]);

# XXX: test -s greater than 3

is_output($svk, sync => ['-s' => 3, '//trunk'],
          [(map { qr'.*'} (1..8)),
	   'Syncing '.$uri,
	   'Retrieving log information from 3 to 3',
	   'Committed revision 2 from revision 3.',
	   'Syncing '.$uri]);

$svk->mkdir(-m => 'xxx', '/test/XX');
$svk->cp(-m => 'get A/P/pe from r1', '/test/A/P/pe@1', '/test/pe');
$svk->cp(-m => 'get B/S/P from r2', '/test/B/S/P@2', '/test/P');
is_output($svk, sync => [-t5 => '//trunk'],
	  ['Syncing '.$uri,
	   'Retrieving log information from 4 to 5',
	   'Committed revision 3 from revision 4.',
	   'Committed revision 4 from revision 5.']);
is_output($svk, 'cat', ['//trunk/pe'],
	  ['first line in pe',
	   '2nd line in pe']);

is_output($svk, sync => [-t6 => '//trunk'],
	  ['Syncing '.$uri,
	   'Retrieving log information from 6 to 6',
	   'Committed revision 5 from revision 6.']);

is_output($svk, 'cat', ['//trunk/P/pe'],
	  ['first line in pe',
	   '2nd line in pe']);

# XXX: exam properties for recorded copies.


# XXX: test with snapshot mirroring of subdir
