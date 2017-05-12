#!/usr/bin/perl -w
use strict;
use Test::More;
use SVK::Test;
use Pushmi::Test;
use Pushmi::Mirror;
use FindBin;

plan tests => 10;

my ($xd, $svk) = build_test('test');

our $output;

my ($srepospath, $spath, $srepos) = $xd->find_repos ('/test/', 1);
start_memcached();

$svk->mkdir('-m', 'init', '/test/A');

my ($copath,  $corpath)  = get_copath('basic-svn');
my ($scopath, $scorpath) = get_copath('basic-svk');

my $uri = uri($srepospath.($spath eq '/' ? '' : $spath));

my ($repospath, $path, $repos) = $xd->find_repos ('//', 1);
ok( Pushmi::Mirror->install_hook($repospath) );

my $muri = uri($repospath.($path eq '/' ? '' : $path));

$svk->mirror('//', $uri);

is_output($svk, 'sync', ['//'],
	  ["Syncing $uri",
	   'Retrieving log information from 1 to 1',
	   'Committed revision 1 from revision 1.']);

is_svn_output(['co', $muri, $copath],
	      ['A    t/checkout/basic-svn/A',
	       'Checked out revision 1.']);
chdir($copath);

overwrite_file("fromsvn.txt", "orz\n");
append_file("fromsvn.txt", "line line line line line line line line\n") for 1..100000;
use Time::HiRes qw(time sleep);
is_svn_output(['add', 'fromsvn.txt'],
	      ['A         fromsvn.txt']);

if ( fork() == 0 ) {

# commit a very large file in the child. which should take longer than the mkdir
    is_svn_output(
        [ 'ci', -m => 'add fromsvn' ],
        [   'Adding         fromsvn.txt',
            'Transmitting file data .',
            qr'Committed revision \d.'
        ]
    );
    exit;
}

my $Test = Test::Builder->new;
$Test->current_test( $Test->current_test + 1 );


sleep 0.5;
is_svn_output(['mkdir', -m => 'race!', "$muri/mkdir"],
	      ['', qr'Committed revision \d.'], []);


wait;
$svk->pg('svn:log', '--revprop', '-r2', '//');
my $m_log2 = $output;
chomp $m_log2;
is_output($svk, 'pg', ['svn:log', '--revprop', '-r2', '/test/'],
	 [$m_log2]);

$svk->pg('svn:log', '--revprop', '-r3', '//');
my $m_log3 = $output;
chomp $m_log3;
is_output($svk, 'pg', ['svn:log', '--revprop', '-r3', '/test/'],
	 [$m_log3]);

is($srepos->fs->youngest_rev, 3, 'committed via hook');

is($repos->fs->youngest_rev, 3, 'committed via hook');

