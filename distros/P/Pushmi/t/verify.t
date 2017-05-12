#!/usr/bin/perl -w
use strict;
use Test::More;
use SVK::Test;
use Pushmi::Test;
use FindBin;
use File::Temp;
use SVK::Util qw(can_run abs_path);
use File::Copy 'copy';
use YAML::Syck;
my $f;
my $lf;
BEGIN {
    $ENV{PATH} = abs_path("$FindBin::Bin/../utils:").$ENV{PATH};

    my $verify_mirror = can_run('verify-mirror');
    plan skip_all => "Can't find verify-mirror" unless $verify_mirror;

    $f = File::Temp->new(TEMPLATE => 'pushmiXXXX', DIR => File::Spec->tmpdir);

    $ENV{PUSHMI_CONFIG} = $f->filename;

    my $perl = join(' ', $^X, map { "'-I$_'" } @INC);
    my $config = { username => 'test',
		   password => 'test',
		   authproxy_port => 8123,
		   verify_mirror => "$perl $verify_mirror"};

    print $f Dump($config);

    $lf = $f->filename; $lf =~ s/pushmi/pushmi-log/;
    copy 't/pushmi-log.conf', $lf;
}
my $pid = $$;

use Pushmi::Mirror;

plan tests => 8;

my ($xd, $svk) = build_test('test');

our $output;

my ($srepospath, $spath, $srepos) = $xd->find_repos ('/test/', 1);

$svk->mkdir('-m', 'init', '/test/A');

my ($copath,  $corpath)  = get_copath('basic-svn');
my ($scopath, $scorpath) = get_copath('basic-svk');

my $uri = uri($srepospath.($spath eq '/' ? '' : $spath));

my ($repospath, $path, $repos) = $xd->find_repos ('//', 1);
my $depot = $xd->find_depot('');
$depot->repos->fs->change_rev_prop(0, 'pushmi:auto-verify', '*');
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


$svk->mkdir('-m', 'more dir', '/test/newdir');
is_output($svk, 'sync', ['//'],
	  ["Syncing $uri",
           'Retrieving log information from 3 to 3',
	   'Committed revision 3 from revision 3.']);


$depot->repos->fs->change_rev_prop(0, 'pushmi:inconsistent', '2');

append_file("fromsvn.txt", "orz\n");

is_svn_output(['ci', -m => 'add fromsvn'],
	      ['Sending        fromsvn.txt',
	       'Transmitting file data .'],
	      ['svn: Commit failed (details follow):',
	       qr{svn: 'pre-commit' hook failed.*:},
	       "Pushmi slave in inconsistency.  Please use the master repository at $uri",
	       'and contact your administrator.  Sorry for the inconveniences.', '']);


END { return unless $$ == $pid; wait; unlink $lf }
