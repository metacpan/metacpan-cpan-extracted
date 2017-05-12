#!/usr/bin/perl -w

# test for the case that read access repository in slave, only
# proxying authn requests on write.
use strict;

use Pushmi::Test;
use SVK::Util qw(can_run abs_path);
use SVK::Test;
use Test::More;
BEGIN { check_apache }

plan skip_all => 'mod_perl required' unless eval { require ModPerl::Config; 1 };
plan tests => 7;

use File::Spec::Functions qw(rel2abs catdir catfile);

our $output;

my ($xd, $svk) = build_test('master', 'slave');
my $tree = create_basic_tree ($xd, '/master/');

my $masterdepot = $xd->find_depot('master');
my $slavedepot = $xd->find_depot('slave');

my $apache_root = rel2abs(catdir ('t', 'apache_master'));
my ($passwd, $policy) = map { catfile($apache_root, $_) }
                          qw/svnpasswd svnpolicy/;

my ( $master, $master_url ) = get_dav_server(
    apache_root => rel2abs( catdir( 't', 'apache_master' ) ),
    repospath   => $masterdepot->repospath,,
    map { $_ => catfile( $apache_root, $_ ) } qw/svnpasswd svnpolicy/
);
diag $master_url;
overwrite_file($passwd, "test:LM9XDLRiC7OUE
mirror:TUcTg/K0XfIcI
"); # test: test, mirror: secret
overwrite_file($policy, q{
[/]
mirror = rw
test = r
* = r
[/X]
mirror = rw
test = rw
* = r

});

my $perl = join(' ', $^X, map { "'-I$_'" } abs_path(@INC));
my $pushmi = can_run('pushmi') or die "can't find pushmi";
my ( $slave, $slave_url ) = get_dav_server(
    apache_root => rel2abs( catdir( 't', 'apache_slave' ) ),
    repospath   => $slavedepot->repospath,
    extra_modules => ['perl'],
    extra_config => qq{

PerlSetVar SVNPath @{[$slavedepot->repospath]}
PerlSetVar PushmiConfig $FindBin::Bin/pushmi.conf
PerlSetVar Pushmi "}.("$perl $pushmi").qq{"
<LimitExcept GET PROPFIND OPTIONS REPORT>
Require valid-user
[% IF AP2_VERSION == '2.2' %]
AuthBasicProvider Pushmi::Apache::RelayProvider
[% ELSE %]
PerlAuthenHandler Pushmi::Apache::AuthCommit
[% END %]
</LimitExcept>
},
);

$master->start;
{
    local $ENV{PERL5LIB}=join(':', map { abs_path($_) } @INC);
    $slave->start;
}

start_memcached();

#my $perlbal_port = '9998';
#my $perlbal_url = start_perlbal($perlbal_port);
my ($perlbal_url, $perlbal_port) = ($slave_url, 5009);
diag $perlbal_url;

run_pushmi('mirror', $slavedepot->repospath, $master_url);
system('svn', 'mkdir', '--non-interactive', '--no-auth-cache', '--username' => 'mirror', '--password' => 'secret', -m => 'mkdir', "$master_url/X");
run_pushmi('sync', $slavedepot->repospath);

my ($copath,  $corpath)  = get_copath('auth-relayed-svn');

system("svn ls $perlbal_url/A");
is_svn_output(['co', '--non-interactive', '--no-auth-cache', "$perlbal_url/A", $copath],
	      ['A    t/checkout/auth-relayed-svn/Q',
	       'A    t/checkout/auth-relayed-svn/Q/qu',
	       'A    t/checkout/auth-relayed-svn/Q/qz',
	       'A    t/checkout/auth-relayed-svn/be',
	       'Checked out revision 3.']);

is_svn_output(['mkdir', '--non-interactive', '--no-auth-cache', -m => 'mkdir', "$perlbal_url/X/orzzzz"],
	      [],
	      [qr{svn: MKACTIVITY of '/svn/\!svn/act/.*': authorization failed \(http://localhost:$perlbal_port\)}]);

is_svn_output(['mkdir', '--non-interactive', '--no-auth-cache', '--username' => 'test', '--password' => 'wrong', -m => 'mkdir', "$perlbal_url/X/orzzzz"],
	      [],
	      [qr{svn: MKACTIVITY of '/svn/\!svn/act/.*': authorization failed \(http://localhost:$perlbal_port\)}]);

is_svn_output(['mkdir', '--non-interactive', '--no-auth-cache', '--username' => 'test', '--password' => 'test', -m => 'mkdir', "$perlbal_url/X/orzzzz"],
	      ['','Committed revision 4.']);

is($masterdepot->repos->fs->revision_prop(4, 'svn:author'), 'test', 'user is correct');
is($slavedepot->repos->fs->revision_prop(4, 'svn:author'), 'test', 'user is correct');

# XXX why do we need to authenticate as test?? svn_authz is totally crazy

is_svn_output(['sw', '--non-interactive', '--no-auth-cache', '--username' => 'test', '--password' => 'test', '--relocate', "$perlbal_url/A", "$master_url/A", $copath],
	      []);

