#!/usr/bin/perl -w
use strict;
use Test::More;
use SVN::Mirror;
use File::Path;
use File::Spec;

if( -d '/tmp/p4testroot' && eval "use VCP::Dest::svk; 1" ) {
    plan tests => 3;
}
else {
    plan skip_all => 'VCP::Dest::svk not installed; p4 needs to be setup';
}

my $m;

# setup the tests here
my $repospath = "t/repos";
rmtree ([$repospath]) if -d $repospath;

my $abs_path = File::Spec->rel2abs( $repospath ) ;

$m = SVN::Mirror->new (target_path => 'p4-trunk',
		       repospath => $abs_path, repos_create => 1,
		       source => 'p4:anonymous@localhost:16666://depot/...',
		       options => [qw'--branch-only=trunk --source-trunk=foo-trunk']);
is (ref $m, 'SVN::Mirror::VCP');
$m->init;
$m->run;
ok(1);

$m = SVN::Mirror->new (target_path => 'p4-all',
		       repospath => $abs_path, repos_create => 1,
		       source => 'p4:anonymous@localhost:16666://depot/...',
		       options => [qw'--source-trunk=foo-trunk --source-branches=foo-']);

$m->init;
$m->run;
ok(1);
