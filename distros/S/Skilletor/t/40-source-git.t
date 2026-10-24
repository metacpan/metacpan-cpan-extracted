#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use FindBin;
use lib "$FindBin::Bin/lib";
use SkilletorTest qw( error_of git_ok git_out bare_remote );

use Path::Tiny qw( path tempdir );
use Skilletor::Source::Git;

# Against local bare repos over file:// – no network.
sub setup {
  my $tmp = tempdir;
  my $repo = bare_remote($tmp);
  return ( $tmp, $repo );
}

sub source {
  my ( $tmp, $repo, %args ) = @_;
  return Skilletor::Source::Git->new( url => $repo->{url}, cache_root => $tmp->child('cache')->stringify, %args );
}

sub short { git_out( $_[0], 'rev-parse', '--short', $_[1] ) }

subtest 'first resolve clones and checks out the source; version is git:<short sha>' => sub {
  my ( $tmp, $repo ) = setup();
  my $sha = $repo->{commit}->( 'hello', 'first' );
  my $src = source( $tmp, $repo );
  my $loc = $src->resolve;
  is( path( $loc->{dir}, 'file.txt' )->slurp, 'hello', 'checked out' );
  is( $loc->{dir}, $src->cache_dir, 'in the cache dir' );
  like( $loc->{dir}, qr{/cache/[0-9a-f]{16}\z}, '16 hex digits' );
  is( $loc->{version}, 'git:'.short( $repo->{work}, $sha ), 'version' );
  ok( !exists $loc->{warning}, 'no warning' );
};

subtest 'resolve updates an existing cache after a new commit' => sub {
  my ( $tmp, $repo ) = setup();
  $repo->{commit}->( 'one', 'first' );
  my $src = source( $tmp, $repo );
  $src->resolve;
  my $sha = $repo->{commit}->( 'two', 'second' );
  my $loc = $src->resolve;
  is( path( $loc->{dir}, 'file.txt' )->slurp, 'two', 'updated' );
  is( $loc->{version}, 'git:'.short( $repo->{work}, $sha ), 'new version' );
};

subtest 'a pinned tag stays put when the branch moves on' => sub {
  my ( $tmp, $repo ) = setup();
  $repo->{commit}->( 'v1', 'first' );
  $repo->{tag}->('v1');
  $repo->{commit}->( 'v2', 'second' );
  my $loc = source( $tmp, $repo, ref => 'v1' )->resolve;
  is( path( $loc->{dir}, 'file.txt' )->slurp, 'v1', 'tag content' );
  isnt( source( $tmp, $repo, ref => 'v1' )->cache_dir, source( $tmp, $repo )->cache_dir, 'a ref never shares the unpinned cache' );
};

subtest 'check: false when unchanged, true after a new commit, true without a version' => sub {
  my ( $tmp, $repo ) = setup();
  $repo->{commit}->( 'one', 'first' );
  my $src = source( $tmp, $repo );
  my $v = $src->resolve->{version};
  ok( !$src->check($v), 'unchanged' );
  ok( !$src->check( 'git:'.uc substr( $v, 4 ) ), 'the sha compares ignoring case' );
  ok( $src->check( uc $v ), 'an upper-case GIT: prefix is no prefix (as in the reference)' );
  $repo->{commit}->( 'two', 'second' );
  ok( $src->check($v), 'changed' );
  ok( $src->check(undef), 'nothing locked' );
  ok( $src->check(''), 'empty version' );
};

subtest 'offline fallback: the cache with a warning when the remote is gone' => sub {
  my ( $tmp, $repo ) = setup();
  $repo->{commit}->( 'cached', 'first' );
  my $src = source( $tmp, $repo );
  my $first = $src->resolve;
  $repo->{gone}->();
  my $second = $src->resolve;
  is( path( $second->{dir}, 'file.txt' )->slurp, 'cached', 'served' );
  is( $second->{version}, $first->{version}, 'same version' );
  like( $second->{warning}, qr/\Agit fetch failed for \Q$repo->{url}\E, using cache \(git fetch --depth 1 -- origin HEAD: .+\)\z/s, 'warning' );
  unlike( $second->{warning}, qr/\n\)\z/, 'git\'s trailing newline is trimmed (k87)' );
};

subtest 'without a cache an unreachable remote names the fetch error' => sub {
  for my $ref ( undef, 'main' ) {
    my $tmp = tempdir;
    my $url = 'file://'.$tmp->child('does-not-exist.git');
    my $src = Skilletor::Source::Git->new( url => $url, ( $ref ? ( ref => $ref ) : () ), cache_root => $tmp->child('cache')->stringify );
    my $err  = error_of( sub { $src->resolve } );
    my $want = $ref // 'HEAD';
    like( $err, qr/\Agit source \Q$url\E failed: git fetch --depth 1 -- origin \Q$want\E: /, 'fetch error, '.$want );
    unlike( $err, qr/cache rejected|rev-parse/, 'no cache talk' );
  }
};

subtest 'full SHA pins of one URL keep independent trees; offline each serves its own' => sub {
  my ( $tmp, $repo ) = setup();
  my $a = $repo->{commit}->( 'A', 'a' );
  my $b = $repo->{commit}->( 'B', 'b' );
  my $la = source( $tmp, $repo, ref => $a )->resolve;
  my $lb = source( $tmp, $repo, ref => $b )->resolve;
  isnt( $la->{dir}, $lb->{dir}, 'two caches' );
  is( path( $la->{dir}, 'file.txt' )->slurp, 'A', 'A' );
  is( path( $lb->{dir}, 'file.txt' )->slurp, 'B', 'B' );
  $repo->{gone}->();
  my $off = source( $tmp, $repo, ref => $a )->resolve;
  is( path( $off->{dir}, 'file.txt' )->slurp, 'A', 'offline A' );
  is( $off->{version}, $la->{version}, 'its version' );
  like( $off->{warning}, qr/using cache/, 'warned' );
};

subtest 'abbreviated SHA pin resolves online' => sub {
  my ( $tmp, $repo ) = setup();
  my $a = $repo->{commit}->( 'A', 'a' );
  $repo->{commit}->( 'B', 'b' );
  my $loc = source( $tmp, $repo, ref => substr( $a, 0, 10 ) )->resolve;
  is( path( $loc->{dir}, 'file.txt' )->slurp, 'A', 'the pinned commit' );
};

subtest 'a pin cache moved to another commit is refused offline' => sub {
  my ( $tmp, $repo ) = setup();
  my $a = $repo->{commit}->( 'A', 'a' );
  my $b = $repo->{commit}->( 'B', 'b' );
  my $src = source( $tmp, $repo, ref => $a );
  my $dir = $src->resolve->{dir};
  # the cache's checkout moved on to B behind skilletor's back
  git_ok( $dir, 'fetch', '-q', 'origin', 'main' );
  git_ok( $dir, 'reset', '-q', '--hard', 'FETCH_HEAD' );
  $repo->{gone}->();
  my $err = error_of( sub { $src->resolve } );
  like( $err, qr/\Agit source \Q$repo->{url}\E failed: git fetch .+; cache rejected \(cached commit $b does not match requested pin $a\)\z/s, 'refused' );
};

subtest 'a tag named like a SHA prefix resolves by name, online and from its cache' => sub {
  my ( $tmp, $repo ) = setup();
  $repo->{commit}->( 'dated', 'a' );
  $repo->{tag}->('20261019');
  $repo->{commit}->( 'later', 'b' );
  my $src = source( $tmp, $repo, ref => '20261019' );
  is( path( $src->resolve->{dir}, 'file.txt' )->slurp, 'dated', 'online' );
  $repo->{gone}->();
  my $off = $src->resolve;
  is( path( $off->{dir}, 'file.txt' )->slurp, 'dated', 'offline' );
  like( $off->{warning}, qr/using cache/, 'warned, not refused' );
};

subtest 'check on a SHA pin: unchanged at the pin without the remote' => sub {
  my ( $tmp, $repo ) = setup();
  my $a = $repo->{commit}->( 'A', 'a' );
  my $src = source( $tmp, $repo, ref => $a );
  my $v = $src->resolve->{version};
  $repo->{gone}->();
  ok( !$src->check($v), 'no remote needed' );
  ok( !$src->check( 'git:'.substr( $a, 0, 12 ) ), 'any prefix of the pin' );
  ok( error_of( sub { $src->check('git:0000000') } ), 'another commit asks the remote (gone: error)' );
};

subtest 'check on tags: lightweight and annotated compare the commit' => sub {
  for my $annotated ( 0, 1 ) {
    my ( $tmp, $repo ) = setup();
    $repo->{commit}->( 'A', 'a' );
    $repo->{tag}->( 'v1', $annotated );
    my $src = source( $tmp, $repo, ref => 'v1' );
    my $v = $src->resolve->{version};
    ok( !$src->check($v), ( $annotated ? 'annotated' : 'lightweight' ).': unchanged' );
    $repo->{commit}->( 'B', 'b' );
    git_ok( $repo->{work}, 'tag', '-f', ( $annotated ? ( '-a', '-m', 'v1' ) : () ), 'v1' );
    git_ok( $repo->{work}, 'push', '-q', '-f', $repo->{url}, 'v1' );
    ok( $src->check($v), ( $annotated ? 'annotated' : 'lightweight' ).': moved' );
  }
};

subtest 'remote_commit ranks as git fetch does' => sub {
  my $src = Skilletor::Source::Git->new( url => 'x', cache_root => '/c' );
  my $ls = join '', map { "$_->[0]\t$_->[1]\n" }
    [ 'AAAA', 'refs/heads/v1' ], [ 'BBBB', 'refs/tags/v1' ], [ 'CCCC', 'refs/tags/v1^{}' ], [ 'DDDD', 'HEAD' ];
  is( $src->remote_commit( $ls, 'v1' ), 'cccc', 'tag before branch, peeled' );
  is( $src->remote_commit( $ls, 'HEAD' ), 'dddd', 'HEAD' );
  is( $src->remote_commit( $ls, 'nope' ), '', 'none' );
};

subtest 'k85: a ref shaped like an option never runs as one' => sub {
  my ( $tmp, $repo ) = setup();
  $repo->{commit}->( 'A', 'a' );
  my $marker = $tmp->child('pwned');
  my $src = source( $tmp, $repo, ref => '--upload-pack=touch '.$marker );
  ok( error_of( sub { $src->resolve } ), 'resolve fails' );
  ok( $src->check('git:abc'), 'check: changed' );
  ok( !-e $marker, 'the command never ran' );
  my $addr = Skilletor::Source::Git->new( url => '--upload-pack=touch '.$marker, cache_root => $tmp->child('c2')->stringify );
  ok( error_of( sub { $addr->resolve } ), 'an option-shaped address fails' );
  ok( error_of( sub { $addr->check('git:abc') } ), 'check fails' );
  ok( !-e $marker, 'never ran' );
};

subtest 'k90: a cache whose origin names another address is pointed back at the source' => sub {
  my ( $tmp, $repo ) = setup();
  $repo->{commit}->( 'A', 'a' );
  my $src = source( $tmp, $repo );
  my $dir = $src->resolve->{dir};
  git_ok( $dir, 'remote', 'set-url', 'origin', 'file:///nowhere' );
  $repo->{commit}->( 'B', 'b' );
  my $loc = $src->resolve;
  is( path( $loc->{dir}, 'file.txt' )->slurp, 'B', 'fetched from the source' );
  is( git_out( $dir, 'config', 'remote.origin.url' ), $repo->{url}, 'origin repaired' );
};

subtest 'k90/k92: a cache without origin or fetch refspec is completed, objects kept' => sub {
  my ( $tmp, $repo ) = setup();
  $repo->{commit}->( 'A', 'a' );
  my $src = source( $tmp, $repo );
  my $dir = $src->resolve->{dir};
  git_ok( $dir, 'config', '--unset', 'remote.origin.fetch' );
  my $loc = $src->resolve;
  is( git_out( $dir, 'config', 'remote.origin.fetch' ), '+refs/heads/*:refs/remotes/origin/*', 'refspec restored' );
  git_ok( $dir, 'remote', 'remove', 'origin' );
  $repo->{commit}->( 'B', 'b' );
  is( path( $src->resolve->{dir}, 'file.txt' )->slurp, 'B', 'origin re-added' );
};

subtest 'k92: offline, a killed reset\'s leftovers are cleaned; a clean cache is served without writes' => sub {
  my ( $tmp, $repo ) = setup();
  $repo->{commit}->( { 'file.txt' => 'A', '.gitignore' => "ignored\n" }, 'a' );
  my $src = source( $tmp, $repo );
  my $dir = $src->resolve->{dir};
  $repo->{gone}->();
  path( $dir, 'file.txt' )->spew('half-written');
  path( $dir, 'extra.txt' )->spew('from the next commit');
  path( $dir, 'ignored' )->spew('ignored leftover');
  my $loc = $src->resolve;
  is( path( $dir, 'file.txt' )->slurp, 'A', 'tracked file restored' );
  ok( !-e path( $dir, 'extra.txt' ), 'untracked leftover gone' );
  ok( !-e path( $dir, 'ignored' ), 'ignored leftover gone' );
  like( $loc->{warning}, qr/using cache/, 'served with a warning' );
  my $index = path( $dir, '.git', 'index' );
  my $mtime = ( stat $index )[9];
  utime 1000, 1000, "$index";
  $src->resolve;
  is( ( stat $index )[9], 1000, 'clean cache: the index is not rewritten' );
};

subtest 'GIT_DIR exported never redirects a cache\'s git' => sub {
  my ( $tmp, $repo ) = setup();
  $repo->{commit}->( 'A', 'a' );
  my $outer = $tmp->child('outer');
  $outer->mkpath;
  git_ok( "$outer", 'init', '-q', '-b', 'main' );
  local $ENV{GIT_DIR} = $outer->child('.git')->stringify;
  local $ENV{GIT_WORK_TREE} = "$outer";
  my $loc = source( $tmp, $repo )->resolve;
  is( path( $loc->{dir}, 'file.txt' )->slurp, 'A', 'the cache got the checkout' );
  ok( !-e $outer->child('file.txt'), 'the exported repository did not' );
};

subtest 'k84: sweep removes stale lock files in git caches and nothing else' => sub {
  my $root = tempdir;
  my $cache = $root->child('0123456789abcdef');
  my $git = $cache->child('.git');
  $git->child( 'refs', 'heads' )->mkpath;
  $git->child('reftable')->mkpath;
  my @stale = ( $git->child('index.lock'), $git->child('shallow.lock'), $git->child( 'refs', 'heads', 'main.lock' ), $git->child( 'reftable', 'tables.list.lock' ) );
  my @fresh = ( $git->child('config.lock') );
  my @other = ( $git->child('random.lock'), $root->child( 'not-a-cache', '.git', 'index.lock' ) );
  $_->parent->mkpath, $_->spew('x') for @stale, @fresh, @other;
  my $old = time - 10 * 60;
  utime $old, $old, "$_" for @stale, @other;
  Skilletor::Source::Git->sweep_cache("$root");
  ok( !-e $_, 'stale removed: '.$_->relative($root) ) for @stale;
  ok( -e $_, 'kept: '.$_->relative($root) ) for @fresh, @other;
  Skilletor::Source::Git->sweep_cache( $root->child('missing')->stringify );
  pass('a missing root is silent');
};

done_testing;
