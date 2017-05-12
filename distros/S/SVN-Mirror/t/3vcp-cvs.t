#!/usr/bin/perl -w
use strict;
use Test::More;
use SVN::Mirror;
use File::Path;
use File::Spec;

if( eval "use VCP::Dest::svk; 1" ) {
    plan tests => 10;
}
else {
    plan skip_all => 'VCP::Dest::svk not installed';
}

my $m;

my $repospath = "t/repos";
rmtree ([$repospath]) if -d $repospath;

my $abs_path = File::Spec->rel2abs( $repospath ) ;

my $cvsroot = File::Spec->rel2abs( "t/cvs-test-data" ) ;
$m = SVN::Mirror->new (target_path => 'cvs-trunk',
		       repospath => $abs_path,
		       repos_create => 1,
		       options => ['--branch-only=trunk'],
		       source => "cvs:$cvsroot:kuso/...");
$m->init;
is_deeply ($m->{options}, ["--branch-only=trunk"]);
$m = SVN::Mirror->new (target_path => 'cvs-trunk',
		       repospath => $abs_path,
		       repos_create => 1,
		       get_source => 1);
$m->init;
is (ref $m, 'SVN::Mirror::VCP');
is ($m->{source}, "cvs:$cvsroot:kuso/...");
is_deeply ($m->{options}, ["--branch-only=trunk"]);
$m->run;

my ($m2, $mpath);
($m2, $mpath) = SVN::Mirror::has_local ($m->{repos}, "$m->{source_uuid}:$m->{source_path}");
ok ($m2);
is ("$m2->{target_path}$mpath", '/cvs-trunk');

($m2, $mpath) = SVN::Mirror::has_local ($m->{repos}, "$m->{source_uuid}:$m->{source_path}/blah");
ok ($m2);
is ("$m2->{target_path}$mpath", '/cvs-trunk/blah');

# check '/cvs-trunk/blah/more'

$m = SVN::Mirror->new (target_path => 'cvs-all', repospath => $abs_path,
		       source => "cvs:$cvsroot:kuso/...");
$m->init;
$m->run;
ok(1);
# check '/cvs-all/trunk/more'

$m = SVN::Mirror->new (target_path => 'cvs-partial', repospath => $abs_path,
		       options => ['--branch-only=trunk,somebranch,anotherbranch'],
		       source => "cvs:$cvsroot:kuso/...");
$m->init;
$m->run;
ok(1);
$m->delete;
