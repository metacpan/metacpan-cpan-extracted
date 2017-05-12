#!/usr/bin/perl -w
use strict;
use Test::More;
use SVK::Test;
eval { require SVN::Mirror; 1 } or plan skip_all => 'require SVN::Mirror';
plan tests => 3;

my ($xd, $svk) = build_test('test');

our $output;

my ($srepospath, $spath, $srepos) = $xd->find_repos ('/test/A', 1);
$svk->mkdir ('-m', 'init', '/test/A');

my ($copath, $corpath) = get_copath ('svnhook-svn');

my $uri = uri($srepospath.($spath eq '/' ? '' : $spath));

my ($repospath, $path, $repos) = $xd->find_repos ('//m', 1);
my $muri = uri($repospath.($path eq '/' ? '' : $path));

$svk->mirror('//m', $uri);

is_output($svk, 'sync', ['//m'],
	  ["Syncing $uri",
	   'Retrieving log information from 1 to 1',
	   'Committed revision 2 from revision 1.']);

is_output($svk, 'sync', ['//m'],
	  ["Syncing $uri"]);

my $hook;
{
    local $/;
    $hook = install_perl_hook($repospath, 'pre-commit', <DATA>);
}
SKIP: {
skip "Can't run hooks", 1 unless -x $hook;

$svk->mkdir('-m', 'A/X', '/test/A/X');
is_output($svk, 'sync', ['//m'],
	  ["Syncing $uri",
	   'Retrieving log information from 2 to 2',
	   qr"A repository hook failed: .*'?pre-commit'? hook .* output.*:",
	   'hate']);
}
__DATA__
print STDERR "hate";
exit 1;
