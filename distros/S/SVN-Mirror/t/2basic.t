#!/usr/bin/perl
use Test::More;
use SVN::Mirror;
use File::Path;
use File::Spec;
use URI::file;
use strict;

plan skip_all => "can't find svnadmin"
    unless `svnadmin --version` =~ /version/;

plan tests => 15;
my $repospath = "t/repos";

rmtree ([$repospath]) if -d $repospath;
$ENV{SVNFSTYPE} ||= (($SVN::Core::VERSION =~ /^1\.0/) ? 'bdb' : 'fsfs');

my $repos = SVN::Repos::create($repospath, undef, undef, undef,
			       {'fs-type' => $ENV{SVNFSTYPE}})
    or die "failed to create repository at $repospath";

my $uri = URI::file->new_abs( $repospath ) ;

`svn mkdir -m 'init' $uri/source`;
`svnadmin load --parent-dir source $repospath < t/test_repo.dump`;

my $m = SVN::Mirror->new(target_path => '/fullcopy', repos => $repos,
			 source => "$uri/source");
is (ref $m, 'SVN::Mirror::Ra');
$m->init ();

$m = SVN::Mirror->new (target_path => '/fullcopy', repos => $repos,
		       get_source => 1,);

is ($m->{source}, "$uri/source");
$m->init ();
$m->run ();

my @mirrored = SVN::Mirror::list_mirror ($repos);
is_deeply ([sort @mirrored], ['/fullcopy'],
	   'list mirror');
is ((SVN::Mirror::is_mirrored ($repos, '/fullcopy'))[1], '',
    'is_mirrored anchor');
is ((SVN::Mirror::is_mirrored ($repos, '/fullcopy/svnperl_002'))[1], '/svnperl_002',
    'is_mirrored descendent');
is_deeply ([SVN::Mirror::is_mirrored ($repos, '/nah')], [],
	  'is_mirrored none');

my $fs = $repos->fs;
my $uuid = $fs->get_uuid;
my $root = $fs->revision_root ($fs->youngest_rev);

is ((SVN::Mirror::has_local ($repos, "$uuid:/source/svnperl/t"))[1], '/svnperl/t',
    'has_local descendent');
is ((SVN::Mirror::has_local ($repos, "$uuid:/source"))[1], '',
    'has_local anchor');
is_deeply ([SVN::Mirror::has_local ($repos, "$uuid:/source-non")], [],
	   'has_local none');


$m = SVN::Mirror::has_local ($repos, "$uuid:/source");
is ($m->find_local_rev (28), 58, 'find_local_rev');
is (scalar $m->find_remote_rev (58), 28, 'find_remote_rev');
is_deeply ({$m->find_remote_rev (58)}, {$m->{source_uuid} => 28}, 'find_remote_rev - hash');

$m->delete;

@mirrored = SVN::Mirror::list_mirror ($repos);
is_deeply (\@mirrored, [], 'discard mirror');

$m = SVN::Mirror->new(target_path => '/partial', repos => $repos,
		      source => "$uri/source/svnperl_002");
$m->init ();
$m->run ();

ok(1);
@mirrored = SVN::Mirror::list_mirror ($repos);
is_deeply ([sort @mirrored], ['/partial'],
	   'list mirror');

