#!/usr/bin/perl
use Test::More;
use SVN::Mirror;
use File::Path;
use URI::file;
use strict;

plan skip_all => "relay doesn't work with svn < 1.1.0"
    unless $SVN::Core::VERSION ge '1.1.0';

plan skip_all => "can't find svnadmin"
    unless `svnadmin --version` =~ /version/;

plan tests => 9;
my $repospath = "t/repos";

rmtree ([$repospath]) if -d $repospath;
$ENV{SVNFSTYPE} ||= (($SVN::Core::VERSION =~ /^1\.0/) ? 'bdb' : 'fsfs');

my $repos = SVN::Repos::create($repospath, undef, undef, undef,
			       {'fs-type' => $ENV{SVNFSTYPE}})
    or die "failed to create repository at $repospath";

my $uri = URI::file->new_abs( $repospath ) ;

`svn mkdir -m 'init' $uri/source`;
`svnadmin load --parent-dir source $repospath < t/test_repo.dump`;

my $rrepospath = 't/repos.relayed';
rmtree ([$rrepospath]) if -d $rrepospath;
my $rrepos = SVN::Repos::create($rrepospath, undef, undef, undef,
				{'fs-type' => $ENV{SVNFSTYPE} || 'bdb'})
    or die "failed to create repository at $rrepospath";

my $ruri = URI::file->new_abs( $rrepospath ) ;

for (1..50) {
    `svn mkdir -m 'waste-rev' $ruri/waste`;
    `svn rm -m 'waste-rev' $ruri/waste`;
}

my $m = SVN::Mirror->new(target_path => '/fullcopy', repos => $rrepos,
			 source => "$uri/source");
$m->init;
is ($m->{source}, "$uri/source");
is ($m->{rsource}, "$uri/source");
$m->run;


$m = SVN::Mirror->new(target_path => '/newcopy', repos => $rrepos,
		      source => "$ruri/fullcopy");
$m->init;
is ($m->{source}, "$uri/source");
is ($m->{rsource}, "$ruri/fullcopy");

$m = SVN::Mirror->new (target_path => '/newcopy', repos => $rrepos,
		       get_source => 1);
$m->init;
is ($m->{source}, "$uri/source");
is ($m->{rsource}, "$ruri/fullcopy");
$m->run;
#print `svn log -v $ruri`;
$m->switch ("$uri/source");

$m = SVN::Mirror->new(target_path => '/newcopy-svnperl', repos => $rrepos,
		      source => "$ruri/fullcopy/svnperl");
$m->init;
is ($m->{source}, "$uri/source/svnperl");
is ($m->{rsource}, "$ruri/fullcopy/svnperl");
$m->run;

$m = SVN::Mirror->new(target_path => '/newcopy-root', repos => $rrepos,
		      source => "$ruri/");
eval { $m->init };

ok ($@ =~ m/outside mirror anchor/);
