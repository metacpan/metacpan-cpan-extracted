#!/usr/bin/perl -w
use strict;
# XXX: apache::test seems to alter inc to use blib
require SVK::Command::Merge;
use POSIX qw(setlocale LC_CTYPE);


# XXX: apache::TestConfig assumes lib.pm is compiled.
require lib;

use SVK::Util qw(can_run);

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

my $tree = create_basic_tree ($xd, '/test/');
my ($srepospath, $spath, $srepos) = $xd->find_repos ('/test/A', 1);
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

my $utf8 = SVK::Util::get_encoding;

mkdir($apache_root);

my ($passwd, $policy) = map { catfile($apache_root, $_) }
                          qw/svnpasswd svnpolicy/;

append_file($passwd, "test:LM9XDLRiC7OUE\n"); # password: test
append_file($policy, "[/A]\ntest = rw\n");

$cfg->postamble (Location => "/svn",
		 qq{
DAV svn
SVNPath $srepospath
Require valid-user
AuthType Basic
AuthName "Auth Realm"
AuthUserFile $passwd
AuthzSVNAccessFile $policy
});
$cfg->generate_httpd_conf;
my $server = $cfg->server;
$server->start;
ok ($server->ping, 'server is alive');

my $uri = 'http://'.$server->{name}.'/svn';
#our $DEBUG=1;
#$ENV{DEBUG_INTERACTIVE}=1;

use SVK::Config;
SVK::Config->auth_providers(
    sub {
        [ SVN::Client::get_simple_prompt_provider( \&my_prompt, 2 ) ]
    }
);

my $prompt_called = 0;

sub my_prompt {
    my ($cred, $realm, $default_username, $may_save, $pool) = @_;
    ++$prompt_called;
    $cred->username('test');
    $cred->password('test');
    $cred->may_save(0);
    return $SVN::_Core::SVN_NO_ERROR;
}

$svk->mirror ('//remote', "$uri/A");
is_output ($svk, 'sync', ['//remote'],
	   ["Syncing $uri/A",
	    'Retrieving log information from 1 to 2',
	    'Committed revision 2 from revision 1.',
	    'Committed revision 3 from revision 2.']);
ok($prompt_called, "prompt called");

$svk->mirror('--detach', '//remote');

###### readable root, C requires authz
overwrite_file($policy, "
[/]
* = r
test = rw
[/C]
* =
test = rw
");
$svk->mkdir(-pm => 'something restricited', '/test/C/lala');

$prompt_called = 0;
$svk->mirror ('//remote-full', "$uri");
ok($prompt_called, "prompt called");

is_output ($svk, 'sync', ['//remote-full'],
	   ["Syncing $uri",
	    'Retrieving log information from 1 to 3',
	    'Committed revision 6 from revision 1.',
	    'Committed revision 7 from revision 2.',
	    'Committed revision 8 from revision 3.']);

$server->stop;
print "\n";
