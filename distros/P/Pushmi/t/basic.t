#!/usr/bin/perl -w
use strict;
use Test::More;
use SVK::Test;
use Pushmi::Test;
use Pushmi::Mirror;
use FindBin;

plan tests => 28;

my ($xd, $svk) = build_test('test');

our $output;

my ($srepospath, $spath, $srepos) = $xd->find_repos ('/test/', 1);

$svk->mkdir('-m', 'init', '/test/A');

my ($copath,  $corpath)  = get_copath('basic-svn');
my ($scopath, $scorpath) = get_copath('basic-svk');

my $uri = uri($srepospath.($spath eq '/' ? '' : $spath));

my ($repospath, $path, $repos) = $xd->find_repos ('//', 1);
ok( Pushmi::Mirror->install_hook($repospath) );

start_memcached();
my $muri = uri($repospath.($path eq '/' ? '' : $path));

$svk->mirror('//', $uri);

is_output($svk, 'sync', ['//'],
	  ["Syncing $uri",
	   'Retrieving log information from 1 to 1',
	   'Committed revision 1 from revision 1.']);

is_output($svk, 'sync', ['//'],
	  ["Syncing $uri"]);

is_svn_output(['co', $muri, $copath],
	      ['A    t/checkout/basic-svn/A',
	       'Checked out revision 1.']);
chdir($copath);
overwrite_file("fromsvn.txt", "orz\n");
is_svn_output(['add', 'fromsvn.txt'],
	      ['A         fromsvn.txt']);

is_svn_output(['ci', -m => 'add fromsvn'],
	      ['Adding         fromsvn.txt',
	       'Transmitting file data .',
	       'Committed revision 2.']);
is($srepos->fs->youngest_rev, 2, 'committed via hook');

is_output($svk, 'mkdir', ['-m', 'X', '/test/X'],
	  ['Committed revision 3.']);

append_file("fromsvn.txt", "second orz\n");
is_svn_output(['ci', -m => 'update fromsvn'],
	     ['Sending        fromsvn.txt',
	      'Transmitting file data .',
	      'Committed revision 4.']);
is($srepos->fs->youngest_rev, 4, 'non-conflicting commit');

is_svn_output(['up'],
	      ['A    X',
	       'Updated to revision 4.']);;
ok(-d 'X', 'catch up changes happened before commit');

$svk->co('/test/', $scorpath);
append_file("$scorpath/fromsvn.txt", "this gets in first\n");
is_output($svk, 'ci', [-m => 'commit that gets in', $scorpath],
	  ['Committed revision 5.']);
is($srepos->fs->youngest_rev, 5);
## vanilla svn:
## svn: Commit failed (details follow):
## svn: Out of date: 'a.txt' in transaction '2-1'
is($repos->fs->youngest_rev, 4, "svn didn't commit through");
append_file("fromsvn.txt", "to conflict\n");
is_svn_output(['ci', -m => 'trying to commit outdated change from svn'],
	      ['Sending        fromsvn.txt',
	       'Transmitting file data .'],
	      ['svn: Commit failed (details follow):',
	       qr{svn: 'pre-commit' hook failed.*:},
	       q{Out of date: 'fromsvn.txt' in transaction '5-1'}, '']);

is($srepos->fs->youngest_rev, 5, "svn didn't commit through");
is($repos->fs->youngest_rev, 5, "svn didn't commit through, but updates mirror");

is_svn_output(['ci', -m => 'trying to commit outdated change from svn'],
	      ['Sending        fromsvn.txt'],
	      ['svn: Commit failed (details follow):',
	       q{svn: Out of date: 'fromsvn.txt' in transaction '5-1'}]);

is_svn_output(['up'],
	      ['C    fromsvn.txt',
	       'Updated to revision 5.']);
# svn 1.5 changes the conflict tmp file
my $conflict_mine = -e 'fromsvn.txt.mine.txt' ? 'fromsvn.txt.mine.txt' : 'fromsvn.txt.mine';
ok(-e $conflict_mine, 'conflict in svn up');

unlink('fromsvn.txt');
rename($conflict_mine, 'fromsvn.txt');
is_svn_output(['resolved', 'fromsvn.txt'],
	      [q{Resolved conflicted state of 'fromsvn.txt'}]);
is_svn_output(['ci', -m => 'commit merged change from svn'],
	      ['Sending        fromsvn.txt',
	       'Transmitting file data .',
	       'Committed revision 6.']);
is($srepos->fs->youngest_rev, 6, "svn commits through");
is($repos->fs->youngest_rev, 6, "svn commit through, but updates mirror");

is_svn_output(['mv', 'A', 'B'],
	      ['A         B',
	       'D         A']);
is_svn_output(['ci', -m => 'commit a rename'],
	      ['Deleting       A',
	       'Adding         B', '',
	       'Committed revision 7.']);
is_output($svk, 'log', [ -qvr => '7', '/test/' ],
	  [ qr'.*',
	    qr'.*',
	    'Changed paths:', '  D  /A',
	    '  A  /B (from /A:5)', qr'.*' ]);


