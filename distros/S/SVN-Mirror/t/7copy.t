#!/usr/bin/perl
use Test::More;
use SVN::Mirror;
use File::Path;
use URI::file;
use strict;

plan skip_all => "can't find svnadmin"
    unless `svnadmin --version` =~ /version/;

plan tests => 3;
my $repospath = "t/repos";

rmtree ([$repospath]) if -d $repospath;
$ENV{SVNFSTYPE} ||= (($SVN::Core::VERSION =~ /^1\.0/) ? 'bdb' : 'fsfs');

my $repos = SVN::Repos::create($repospath, undef, undef, undef,
			       {'fs-type' => $ENV{SVNFSTYPE}})
    or die "failed to create repository at $repospath";

my $uri = URI::file->new_abs( $repospath ) ;
`svn mkdir -m 'init' $uri/source`;
`svnadmin load --parent-dir source $repospath < t/copy.dump`;

my $m = SVN::Mirror->new(target_path => '/fullcopy', repos => $repos,
			 source => "$uri/source");
is (ref $m, 'SVN::Mirror::Ra');
$m->init ();

$m = SVN::Mirror->new (target_path => '/fullcopy', repos => $repos,
		       get_source => 1,);

is ($m->{source}, "$uri/source");
$m->init ();
$m->run ();

ok('we survived');
