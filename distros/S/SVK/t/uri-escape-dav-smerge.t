#!/usr/bin/perl -w
use strict;
# XXX: apache::test seems to alter inc to use blib
require SVK::Command::Merge;
use POSIX qw(setlocale LC_CTYPE);


# XXX: apache::TestConfig assumes lib.pm is compiled.
require lib;

use SVK::Util qw(can_run uri_escape $EOL);

BEGIN {
use SVK::Test;
    plan (skip_all => "Test does not run under root") if $> == 0;
    eval { require Apache2 };
    eval { require Apache::Test;
	   $Apache::Test::VERSION >= 1.18 }
	or plan (skip_all => "Apache::Test 1.18 required for testing dav");
}
setlocale (LC_CTYPE, $ENV{LC_CTYPE} = 'en_US.UTF-8')
    or plan skip_all => 'cannot set locale to en_US.UTF-8';

use Apache::TestConfig;
use File::Spec::Functions qw(rel2abs catdir catfile);

our $output;

my ($xd, $svk) = build_test('test');

my $depotpath = '/test/';
my $pool = SVN::Pool->new_default;
my ($depot, $path) = $xd->find_depotpath($depotpath);
{
    local $/ = $EOL;
    my $edit = get_editor ($depot->repospath, $path, $depot->repos);
    $edit->open_root ();

    $edit->add_directory ('/B and K');
    $edit->add_directory ('/B and K/A');
    $edit->add_directory ('/B and K/A/N P1');
    $edit->add_directory ('/B and K/A/N P1/trunk');
    $edit->add_directory ('/B and K/A/N P1/trunk/doc');
    $edit->modify_file (
	$edit->add_file ('/B and K/A/N P1/trunk/doc/ReadMe.txt'),
			"first line in pe$/2nd line in pe$/");
    $edit->add_directory ('/B and K/A/N P1/trunk/src');
    $edit->add_directory ('/B and K/A/N P1/trunk/data');
    $edit->modify_file (
	$edit->add_file ('/B and K/A/N P1/trunk/data/N M/HOWTO.txt'),
			"first line in pe$/2nd line in pe$/");
    $edit->add_directory ('/B and K/A/N P1/branches');
    $edit->add_directory ('/B and K/A/N P1/tags');
    $edit->close_edit ();
}
my ($srepospath, $spath, $srepos) = $xd->find_repos ('/test/B and K', 1);
my (undef, undef, $repos) = $xd->find_repos ('//', 1);

my $apache_root = rel2abs (catdir ('t', 'apache_svn'));
my $apxs = $ENV{APXS} || can_run('apxs2') || can_run ('apxs');
plan skip_all => "Can't find apxs utility. Use APXS env to specify path" unless $apxs;

my $cfg = Apache::TestConfig->new
    ( top_dir => $apache_root,
      t_dir => $apache_root,
      apxs => $apxs,
 )->httpd_config;

plan skip_all => "apache 2.2 changed auth directives."
    if $cfg->server->{version} =~ m|Apache/2\.2|;

unless ($cfg->can('find_and_load_module') and
	$cfg->find_and_load_module ('mod_dav.so') and
	$cfg->find_and_load_module ('mod_dav_svn.so') and
        $cfg->find_and_load_module ('mod_authz_svn.so')) {
    plan skip_all => "Can't find mod_dav_svn and mod_authz_svn";
}

plan tests => 5;

$cfg->postamble (Location => "/svn",
		 qq{DAV svn\n    SVNPath $depot->{repospath}\n});
$cfg->generate_httpd_conf;
my $server = $cfg->server;

$server->start;
ok ($server->ping, 'server is alive');

my $uri = 'http://'.$server->{name}.'/svn';
my $uri_trunk = $uri.'/B and K/A/N P1/trunk';
my $uri_trunk_escape = uri_escape($uri_trunk);

$svk->mirror('//mirror/BK', $uri_trunk);

is_output ($svk, 'mirror', ['--list'], [
    "Path          Source",
    "============================================================",
    "//mirror/BK   $uri/B and K/A/N P1/trunk"]);

is_output ($svk, 'sync', ['//mirror/BK'], [
    "Syncing $uri/B and K/A/N P1/trunk",
    "Retrieving log information from 1 to 1",
    "Committed revision 2 from revision 1."]);

# detach and try with snapshot sync

$svk->copy ('-p', '-m', 'branch', '//mirror/BK', '//local/BK');

my ($copath, $corpath) = get_copath ('uri-smerge');
my ($scopath, $scorpath) = get_copath ('uri-smerge-source');

$svk->checkout ('//mirror/BK', $scopath);
append_file ("$scopath/doc/ReadMe.txt", "modified on trunk\n");
$svk->commit ('-m', 'commit on trunk', $scopath);
$svk->checkout ('//local/BK', $copath);
append_file ("$copath/data/N M/HOWTO.txt", "modified on local branch\n");

chdir($copath);
$svk->commit ('-m', 'commit on local branch');

$svk->sync ('//mirror/BK');

is_output ($svk, 'push', ['-C'],
    ['Auto-merging (0, 5) /local/BK to /mirror/BK (base /mirror/BK:2).',
     '===> Auto-merging (0, 3) /local/BK to /mirror/BK (base /mirror/BK:2).',
     'Empty merge.',
     '===> Auto-merging (3, 5) /local/BK to /mirror/BK (base /mirror/BK:2).',
     'U   data/N M/HOWTO.txt',
     qr'New merge ticket: .*:/local/BK:5']);

is_output ($svk, 'push', [''],
    ['Auto-merging (0, 5) /local/BK to /mirror/BK (base /mirror/BK:2).',
     '===> Auto-merging (0, 3) /local/BK to /mirror/BK (base /mirror/BK:2).',
     qr'Merging back to mirror source http://[^/]+/svn/B and K/A/N P1/trunk.',
     'Empty merge.',
     '===> Auto-merging (3, 5) /local/BK to /mirror/BK (base /mirror/BK:2).',
     qr'Merging back to mirror source http://[^/]+/svn/B and K/A/N P1/trunk.',
     'U   data/N M/HOWTO.txt',
     qr'New merge ticket: .*:/local/BK:5',
     'Merge back committed as revision 3.',
     qr'Syncing http://[^/]+/svn/B and K/A/N P1/trunk',
     'Retrieving log information from 3 to 3',
     'Committed revision 6 from revision 3.']);
