#!/usr/bin/perl
use Test::More;
use SVN::Mirror;
use File::Path;
use File::Spec;
use strict;

plan skip_all => "can't find svnadmin"
    unless `svnadmin --version` =~ /version/;

plan tests => 3;
my $repospath = "t/repos.old";

rmtree ([$repospath]) if -d $repospath;
$ENV{SVNFSTYPE} ||= (($SVN::Core::VERSION =~ /^1\.0/) ? 'bdb' : 'fsfs');

my $repos = SVN::Repos::create($repospath, undef, undef, undef,
			       {'fs-type' => $ENV{SVNFSTYPE}})
    or die "failed to create repository at $repospath";

`svnadmin load --quiet $repospath < t/test_old.dump`;

my $m = SVN::Mirror->new(target_path => '/trunk', repos => $repos, get_source => 1);
eval {$m->init};
ok ($@ =~ m/upgrade/, 'ask for upgrade');

SVN::Mirror::upgrade ($repos);

$m = SVN::Mirror->new(target_path => '/trunk', repos => $repos, get_source => 1);
$m->init;
my @mirrored = SVN::Mirror::list_mirror ($repos);
is_deeply ([sort @mirrored], ['/branches', '/trunk'],
	   'list mirror');
is ($m->find_local_rev (1), 4, 'find_local_rev');
