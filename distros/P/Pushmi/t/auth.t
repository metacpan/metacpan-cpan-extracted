#!/usr/bin/perl -w
use strict;

use SVK::Util qw(can_run abs_path);
use SVK::Test;
use Pushmi::Test;
BEGIN { check_apache() }

use Test::More tests => 11;

use File::Spec::Functions qw(rel2abs catdir catfile);

my ($xd, $svk) = build_test('master', 'slave');
my $tree = create_basic_tree ($xd, '/master/');
my $masterdepot = $xd->find_depot('master');
my $slavedepot = $xd->find_depot('slave');

my $apache_root = rel2abs(catdir ('t', 'apache_master'));
my ($passwd, $policy) = map { catfile($apache_root, $_) }
                          qw/svnpasswd svnpolicy/;

# XXX: write a test which wouldn't fail only if we have svnpolicy
my ( $master, $master_url ) = get_dav_server(
    apache_root => rel2abs( catdir( 't', 'apache_master' ) ),
    repospath   => $masterdepot->repospath,
    map { $_ => catfile( $apache_root, $_ ) } qw/svnpasswd svnpolicy/,
);
diag $master_url;

overwrite_file($passwd, "test:LM9XDLRiC7OUE
mirror:TUcTg/K0XfIcI
"); # test: test, mirror: secret
overwrite_file($policy, q{
[/]
mirror = rw
test = r
[/X]
test = rw

});

my $perl = join(' ', $^X, map { "'-I$_'" } abs_path(@INC));
my $pushmi = can_run('pushmi') or die "can't find pushmi";
my ( $slave, $slave_url ) = get_dav_server(
    apache_root => rel2abs( catdir( 't', 'apache_slave' ) ),
    repospath   => $slavedepot->repospath,
    extra_modules => ['perl'],
    (map { $_ => catfile( $apache_root, $_ ) } qw/svnpasswd svnpolicy/),
    extra_config => qq{
PerlSetVar PushmiConfig $FindBin::Bin/pushmi.conf
Require valid-user
PerlAuthzHandler Pushmi::Apache::AuthCache
},
);

$master->start;
{
    local $ENV{PERL5LIB}=join(':', map { abs_path($_) } @INC);
    $slave->start;
}

start_memcached();
#my $perlbal_port = 9998;
#my $perlbal_url = start_perlbal($perlbal_port);
my ($perlbal_url, $perlbal_port) = ($slave_url, 5009);
diag $perlbal_url;

run_pushmi('mirror', $slavedepot->repospath, $master_url);
system('svn', 'mkdir', '--non-interactive', '--no-auth-cache', '--username' => 'mirror', '--password' => 'secret', -m => 'mkdir', "$master_url/X");

run_pushmi('sync', $slavedepot->repospath);
is_svn_output(['mkdir', '--non-interactive', '--no-auth-cache', '--username' => 'test', '--password' => 'test', -m => 'mkdir', "$perlbal_url/orzzzz"],
	      [],
	      [qr{svn: .*403 Forbidden}]);

#sleep 1 while 1;
is_svn_output(['mkdir', '--non-interactive', '--no-auth-cache', '--username' => 'test', '--password' => 'test', -m => 'mkdir', "$perlbal_url/X/mmmm"],
	      ['','Committed revision 4.']);
diag $slave_url;

is($masterdepot->repos->fs->revision_prop(4, 'svn:author'), 'test', 'user is correct');

is($slavedepot->repos->fs->revision_prop(4, 'svn:author'), 'test', 'user is correct');

my ($copath,  $corpath)  = get_copath('auth-svn');

is_svn_output(['co', '--non-interactive', '--no-auth-cache', '--username' => 'test', '--password' => 'test', "$slave_url/X", $copath],
	      ['A    t/checkout/auth-svn/mmmm',
	       'Checked out revision 4.']);

overwrite_file("$copath/fileA.txt", "fnord");

is_svn_output(['add', "$copath/fileA.txt"],
	      ['A         t/checkout/auth-svn/fileA.txt']);

is_svn_output(['ci', '--non-interactive', '--no-auth-cache', '--username' => 'test', '--password' => '', -m => 'commit a single file', $copath],
	      [],
	      ["svn: Commit failed (details follow):",
	       "svn: OPTIONS request failed on '/svn/X'",
	       "svn: OPTIONS of '/svn/X': authorization failed (http://localhost:$perlbal_port)"]);

is_svn_output(['ci', '--non-interactive', '--no-auth-cache', '--username' => 'test', '--password' => 'test', -m => 'commit a single file', $copath],
	      ['Adding         t/checkout/auth-svn/fileA.txt',
	       'Transmitting file data .',
	       'Committed revision 5.']);



append_file("$copath/fileA.txt", "fnordfnord");


is_svn_output(['ci', '--non-interactive', '--no-auth-cache', '--username' => 'test', '--password' => 'test', -m => 'commit a single file', $copath],
	      ['Sending        t/checkout/auth-svn/fileA.txt',
	       'Transmitting file data .',
	       'Committed revision 6.']);

is_svn_output(['rm', "$copath/mmmm"],
	      ['D         t/checkout/auth-svn/mmmm']);


is_svn_output(['ci', '--non-interactive', '--no-auth-cache', '--username' => 'test', '--password' => 'test', -m => 'commit a single file', $copath],
	      ['Deleting       t/checkout/auth-svn/mmmm',
	       '',
	       'Committed revision 7.']);
