#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use FindBin;
use lib "$FindBin::Bin/lib";
use SkilletorTest qw( error_of make_tar gzip_bytes serve_http );

use Digest::SHA qw( sha256_hex );
use Path::Tiny qw( path tempdir );
use Skilletor::Source::Url;

my $srv = serve_http();

sub tgz { gzip_bytes( make_tar(@_) ) }

my $v1 = tgz(
  { name => 'skills-main/', type => '5' },
  { name => 'skills-main/skills/a/SKILL.md', data => "v1\n" },
  { name => 'skills-main/skills/a/run.sh', data => "#!/bin/sh\n", mode => 0755 },
  { name => 'skills-main/.skilletor-version', data => 'forged' },
);
my $v2 = tgz( { name => 'skills-main/skills/a/SKILL.md', data => "v2\n" }, { name => 'skills-main/skills/b/SKILL.md', data => "b\n" } );

sub source {
  my ( $tmp, $p, %args ) = @_;
  return Skilletor::Source::Url->new( url => $srv->url($p), cache_root => $tmp->child('cache')->stringify, allow_http => 1, %args );
}

subtest 'resolve extracts, strips the top dir, keeps the x bit, drops the reserved entry' => sub {
  my $tmp = tempdir;
  $srv->route( '/v1.tgz', { headers => { ETag => '"e1"' }, body => $v1 } );
  my $src = source( $tmp, '/v1.tgz' );
  my $loc = $src->resolve;
  is( $loc->{version}, 'etag:"e1"', 'version from the ETag' );
  is( path( $loc->{dir}, 'skills/a/SKILL.md' )->slurp, "v1\n", 'content' );
  ok( -x path( $loc->{dir}, 'skills/a/run.sh' ), 'executable' );
  ok( !-x path( $loc->{dir}, 'skills/a/SKILL.md' ), 'not executable' );
  is( path( $loc->{dir}, '.skilletor-version' )->slurp_raw, qq(format 2\netag:"e1"), 'version file, no trailing newline' );
  is( $src->cache_version( $loc->{dir} ), 'etag:"e1"', 'read back' );
  is_deeply( [ sort map { $_->basename } path( $tmp, 'cache' )->children ], [ path( $loc->{dir} )->basename ], 'no stage or backup left' );
  my $req = $srv->requests->[-1];
  is( $req->{headers}{'user-agent'}, 'node', 'requested as Node fetch does' );
  is( $req->{headers}{'accept-encoding'}, 'gzip, deflate', 'accept-encoding' );
  ok( !exists $req->{headers}{'if-none-match'}, 'unconditional the first time' );
};

subtest '304 reuses the cache; a changed ETag swaps the tree' => sub {
  my $tmp = tempdir;
  $srv->route( '/c.tgz', { headers => { ETag => '"e1"' }, body => $v1, status_for => { '"e1"' => 304 } } );
  my $src = source( $tmp, '/c.tgz' );
  my $first = $src->resolve;
  my $second = $src->resolve;
  is( $srv->requests->[-1]{headers}{'if-none-match'}, '"e1"', 'If-None-Match is the cache\'s' );
  is( $srv->requests->[-1]{headers}{'cache-control'}, 'no-cache', 'with fetch\'s no-cache headers' );
  is_deeply( $second, { dir => $first->{dir}, version => 'etag:"e1"' }, '304: the cache' );
  $srv->route( '/c.tgz', { headers => { ETag => '"e2"' }, body => $v2, status_for => { '"e2"' => 304 } } );
  my $third = $src->resolve;
  is( $third->{version}, 'etag:"e2"', 'new version' );
  is( path( $third->{dir}, 'skills/a/SKILL.md' )->slurp, "v2\n", 'new tree' );
  ok( !-e path( $third->{dir}, 'skills/a/run.sh' ), 'old files gone' );
};

subtest 'no ETag: the archive\'s sha256' => sub {
  my $tmp = tempdir;
  $srv->route( '/n.tgz', { body => $v1 } );
  is( source( $tmp, '/n.tgz' )->resolve->{version}, 'sha256:'.sha256_hex($v1), 'sha256 version' );
};

subtest 'offline: the cache with a warning, its own version; no cache: an error' => sub {
  my $tmp = tempdir;
  $srv->route( '/o.tgz', { headers => { ETag => '"o"' }, body => $v1 } );
  my $src = source( $tmp, '/o.tgz' );
  my $dir = $src->resolve->{dir};
  $srv->route( '/o.tgz', { status => 500 } );
  is_deeply( $src->resolve, { dir => $dir, version => 'etag:"o"', warning => 'download failed for '.$srv->url('/o.tgz').', using cache (HTTP 500)' }, 'HTTP 500' );
  my $none = source( tempdir, '/missing.tgz' );
  is( error_of( sub { $none->resolve } ), 'url source '.$srv->url('/missing.tgz').' failed: HTTP 404', 'no cache' );
  my $dead = Skilletor::Source::Url->new( url => 'http://127.0.0.1:1/x.tgz', cache_root => $tmp->child('c2')->stringify, allow_http => 1 );
  is( error_of( sub { $dead->resolve } ), 'url source http://127.0.0.1:1/x.tgz failed: fetch failed', 'connection refused as fetch words it' );
};

subtest 'a cache without a version file (or an older format) has no known version' => sub {
  my $tmp = tempdir;
  $srv->route( '/f.tgz', { headers => { ETag => '"f"' }, body => $v1, status_for => { '"f"' => 304 } } );
  my $src = source( $tmp, '/f.tgz' );
  my $dir = $src->resolve->{dir};
  path( $dir, '.skilletor-version' )->spew_raw('etag:"f"');    # skilletor <= 0.4.1
  is( $src->cache_version($dir), undef, 'old format: unknown' );
  $src->resolve;
  ok( !exists $srv->requests->[-1]{headers}{'if-none-match'}, 'so the GET is unconditional' );
  is( path( $dir, '.skilletor-version' )->slurp_raw, qq(format 2\netag:"f"), 're-extracted in format 2' );
  path( $dir, '.skilletor-version' )->remove;
  $srv->route( '/f.tgz', { status => 503 } );
  is( $src->resolve->{version}, 'unknown', 'offline fallback to a cache without one: unknown' );
};

subtest 'an unsafe or unreadable archive' => sub {
  my $tmp = tempdir;
  $srv->route( '/u.tgz', { headers => { ETag => '"u1"' }, body => $v1 } );
  my $src = source( $tmp, '/u.tgz' );
  my $dir = $src->resolve->{dir};
  $srv->route( '/u.tgz', { headers => { ETag => '"u2"' }, body => tgz( { name => 'ok', data => 'x' }, { name => 'l', type => '2', linkname => '/etc' } ) } );
  is( error_of( sub { $src->resolve } ), 'url source '.$srv->url('/u.tgz').' failed: unsafe tar entry (symlink/hardlink): l', 'unsafe: an error, no fallback' );
  is( path( $dir, 'skills/a/SKILL.md' )->slurp, "v1\n", 'the last good cache stays' );
  $srv->route( '/u.tgz', { headers => { ETag => '"u3"' }, body => 'not gzip at all' } );
  is( $src->resolve->{warning}, 'download failed for '.$srv->url('/u.tgz').', using cache (incorrect header check)', 'not gzip: zlib\'s word, fallback' );
  for my $size ( '-0000001000', '-1', 'zz' ) {
    $srv->route( '/u.tgz', { headers => { ETag => '"u4"' }, body => tgz( { name => 'bad', size => $size, data => '' }, { name => 'x', data => 'x' } ) } );
    is( $src->resolve->{warning}, 'download failed for '.$srv->url('/u.tgz').', using cache (corrupt tar entry (size): bad)', 'size '.$size.': corrupt, fallback' );
    is( path( $dir, 'skills/a/SKILL.md' )->slurp, "v1\n", 'size '.$size.': the cache is untouched' );
  }
  my $fresh = source( $tmp->child('fresh'), '/u.tgz' );
  is( error_of( sub { $fresh->resolve } ), 'url source '.$srv->url('/u.tgz').' failed: corrupt tar entry (size): bad', 'corrupt without a cache: an error' );
  ok( !-e $fresh->cache_dir, 'and no partial tree' );
};

subtest 'check: HEAD and the ETag' => sub {
  my $tmp = tempdir;
  $srv->route( '/h.tgz', { headers => { ETag => '"h1"' }, body => $v1 } );
  my $src = source( $tmp, '/h.tgz' );
  ok( !$src->check('etag:"h1"'), 'same ETag: unchanged' );
  is( $srv->requests->[-1]{method}, 'HEAD', 'a HEAD request' );
  ok( $src->check('etag:"h0"'), 'other ETag: changed' );
  ok( $src->check('sha256:abc'), 'no etag locked: changed' );
  ok( $src->check(undef), 'nothing locked: changed' );
  $srv->route( '/h.tgz', { body => $v1 } );
  ok( $src->check('etag:"h1"'), 'server sends none: changed' );
};

subtest 'https only' => sub {
  my $tmp = tempdir;
  is( error_of( sub { Skilletor::Source::Url->new( url => $srv->url('/x.tgz'), cache_root => "$tmp" )->resolve } ),
    'url source must be https://: '.$srv->url('/x.tgz'), 'http refused without allow_http' );
  is( error_of( sub { Skilletor::Source::Url->new( url => 'http://example.com/x.tgz', cache_root => "$tmp", allow_http => 1 )->check('x') } ),
    'url source must be https://: http://example.com/x.tgz', 'allow_http only for the loopback' );
  is( error_of( sub { Skilletor::Source::Url->new( url => 'https://', cache_root => "$tmp" )->resolve } ), 'Invalid URL', 'what new URL says' );
};

subtest 'sweep: a stage goes, an orphaned backup is put back, another backup goes' => sub {
  my $root = tempdir;
  my $h1 = '0123456789abcdef';
  my $h2 = 'fedcba9876543210';
  path( $root, $h1.'.stage-AbC123', 'x' )->touchpath;
  path( $root, $h2.'.backup-Zz9Yy8', 'tree', 'kept' )->touchpath;
  path( $root, $h1 )->mkpath;
  path( $root, $h1.'.backup-Qq1Ww2', 'tree', 'old' )->touchpath;
  path( $root, 'unrelated.stage-AbC123' )->mkpath;
  Skilletor::Source::Url->sweep_cache("$root");
  is_deeply( [ sort map { $_->basename } $root->children ], [ $h1, $h2, 'unrelated.stage-AbC123' ], 'what remains' );
  ok( -e path( $root, $h2, 'kept' ), 'the last good cache is back in place' );
};

$srv->stop;
done_testing;
