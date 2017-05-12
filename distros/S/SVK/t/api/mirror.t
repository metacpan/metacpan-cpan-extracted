#!/usr/bin/perl -w
use strict;
use Test::More;
use SVK::Test;
use SVK::Mirror;
use SVK::Mirror::Backend::SVNRa;
plan tests => 11;

my ($xd, $svk) = build_test('test');
my ($copath, $corpath) = get_copath ('api-mirror');

our $output;

my $tree = create_basic_tree ($xd, '/test/');
my $depot = $xd->find_depot('');
my $repos = $depot->repos;
my $sdepot = $xd->find_depot('test');
my $srepos = $sdepot->repos;
my $uri = uri($sdepot->repospath);

my $m = SVK::Mirror->create(
        { depot => $depot, path => '/m', backend => 'SVNRa',
	  url => "$uri/A", pool => SVN::Pool->new } );

is_output($svk, 'pg', ['svm:source', '//m'],
	  [uri($sdepot->repospath).'!/A']);

is_output($svk, 'pg', ['svm:uuid', '//m'],
	  [$srepos->fs->get_uuid]);

is_output($svk, 'pg', ['svm:mirror', '//'],
	  ['/m', '' ]);

$m = SVK::Mirror->load(
        { depot => $depot, path => '/m',
	  pool => SVN::Pool->new }
    );

is( $m->url, "$uri/A" );

$m = SVK::Mirror->create(
    {   depot   => $depot,
        path    => '/m2',
        backend => 'SVNRa',
        url     => "$uri/B",
        pool    => SVN::Pool->new
    }
);

is_output($svk, 'pg', ['svm:source', '//m2'],
	  [uri($sdepot->repospath).'!/B']);

is_output($svk, 'pg', ['svm:uuid', '//m2'],
	  [$srepos->fs->get_uuid]);

is_output($svk, 'pg', ['svm:mirror', '//'],
	  ['/m', '/m2', '']);

eval {
SVK::Mirror::Backend::SVNRa->create(
    SVK::Mirror->new(
        { depot => $depot, path => '/m3',
	  url => $uri, pool => SVN::Pool->new }
    )
);
};

is($@, "Mirroring overlapping paths not supported\n");

is_output($svk, 'ls', ['//'], ['m/', 'm2/'], 'm3 not created');

my $mc = SVK::MirrorCatalog->new( { repos => $repos, depot => $depot } );
is_deeply([ sort $mc->entries], ['/m', '/m2']);

$m = SVK::Mirror->load(
        { depot => $depot, path => '/m',
	  pool => SVN::Pool->new }
    );

{
    my @revs;
    $m->traverse_new_changesets(sub { push @revs, $_[0] });
    is_deeply(\@revs, [1,2]);
}

$m->run();
#$m->mirror_changesets();
# XXX: check committed revisions
