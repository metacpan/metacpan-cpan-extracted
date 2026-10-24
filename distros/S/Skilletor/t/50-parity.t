#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use FindBin;
use lib "$FindBin::Bin/lib";
use SkilletorTest qw( error_of git_ok git_out bare_remote make_tar gzip_bytes pax_path serve_http );

use IPC::Open2 qw( open2 );
use Path::Tiny qw( path tempdir );
use Skilletor::Backend;
use Skilletor::JSON qw( js_parse js_stringify );
use Skilletor::Source::Git;
use Skilletor::Source::Url;
use Skilletor::State;

# The reference implementation and the port, side by side on the same remotes and the same
# cache root: what one fetched, the other serves; messages and versions are the same. Needs
# node and the TypeScript tree beside perl/ – a checkout of the skilletor repository.
my $runner = path( $FindBin::Bin, '..', 'maint', 'ts-run.mjs' );
my $src_ts = path( $FindBin::Bin, '..', '..', 'src', 'engine.ts' );
plan skip_all => 'needs the skilletor checkout (../src) and maint/ts-run.mjs' unless $runner->exists && $src_ts->exists;
plan skip_all => 'needs node' unless grep { -x path( $_, 'node' ) } split /:/, $ENV{PATH} // '';
plan skip_all => 'needs the reference\'s node_modules' unless path( $FindBin::Bin, '..', '..', 'node_modules', 'nunjucks' )->exists;

sub ts {
  my ( $req ) = @_;
  my $pid = open2( my $out, my $in, 'node', "$runner" );
  binmode $in, ':raw';
  print {$in} Skilletor::FSUtil::encode_text( js_stringify($req) );
  close $in;
  local $/;
  my $text = <$out>;
  waitpid $pid, 0;
  die 'ts-run failed ('.( $? >> 8 ).'): '.( $text // '' ) unless defined $text && length $text;
  return js_parse( Skilletor::FSUtil::decode_utf8_lossy($text) );
}

sub ts_ok {
  my ( $req ) = @_;
  my $r = ts($req);
  die 'reference failed: '.$r->{error} if exists $r->{error};
  return $r->{result};
}

sub ts_err { ts( $_[0] )->{error} }

subtest 'backend choice (author mode, origins, path) is the reference\'s' => sub {
  my $tmp  = tempdir;
  my $home = $tmp->child('home');
  $home->child( 'dev', 'skills' )->mkpath;
  symlink( $home->child( 'dev', 'skills' ), $home->child('linked') );
  my @sources = (
    { name => 'a', git => 'https://g', local => '~/dev/skills', origins => { git => 'project', local => 'user' } },
    { name => 'b', git => 'https://g', ref => 'v1', local => '~/dev/missing', origins => { git => 'project', local => 'user' } },
    { name => 'c', local => '~/dev/missing', origins => { local => 'project' } },
    { name => 'd', url => 'https://u/x.tgz', path => 'skills', origins => {} },
    { name => 'e', local => '~/linked/', path => [ 'a', 'b' ], origins => { local => 'user' } },
    { name => 'f', local => '~', git => 'https://g', origins => { local => 'user', git => 'user' } },
    { name => 'g', local => 'relative/dir', origins => { local => 'project' } },
  );
  for my $s (@sources) {
    is_deeply( Skilletor::Backend->resolve( $s, "$home" ), ts_ok( { op => 'backend', src => $s, home => "$home" } ), 'source '.$s->{name} );
  }
  my $none = { name => 'z', origins => {} };
  is( error_of( sub { Skilletor::Backend->resolve( $none, "$home" ) } ), ts_err( { op => 'backend', src => $none, home => "$home" } ), 'no backend' );
};

subtest 'trust answers on one trust.json' => sub {
  my $root = tempdir;
  Skilletor::State->new( root => "$root" )->trust( p => { kind => 'git', address => 'https://p' } );
  $root->child('trust.json')->spew_raw( $root->child('trust.json')->slurp_raw =~ s/\}\n\z/}/r );    # any formatting reads
  for my $b ( { kind => 'git', address => 'https://p', origin => 'project' }, { kind => 'url', address => 'https://p', origin => 'project' },
    { kind => 'local', address => '/x', origin => 'user' } ) {
    is( !!Skilletor::State->new( root => "$root" )->is_trusted( p => $b ), !!ts_ok( { op => 'trust', root => "$root", name => 'p', backend => $b } ),
      'is_trusted '.$b->{kind}.' '.$b->{origin} );
  }
};

subtest 'git: one cache, both directions' => sub {
  my $tmp  = tempdir;
  my $repo = bare_remote($tmp);
  my $c1 = $repo->{commit}->( { 'skills/a/SKILL.md' => "one\n", 'run.sh' => "#!/bin/sh\n" }, 'first' );
  chmod 0755, path( $repo->{work}, 'run.sh' );
  git_ok( $repo->{work}, 'add', 'run.sh' );
  git_ok( $repo->{work}, 'commit', '-q', '-m', 'x bit' );
  git_ok( $repo->{work}, 'push', '-q', $repo->{url}, 'main' );
  my %opts = ( url => $repo->{url}, cacheRoot => $tmp->child('cache')->stringify );
  my $perl = Skilletor::Source::Git->new( url => $repo->{url}, cache_root => $opts{cacheRoot} );

  my $t1 = ts_ok( { op => 'git', action => 'resolve', opts => \%opts } );
  my $marker = path( $t1->{dir}, '.git', 'skilletor-parity-marker' );
  $marker->spew('made by the reference');
  my $p1 = $perl->resolve;
  is_deeply( $p1, $t1, 'the port serves the reference\'s cache: same dir, same version' );
  ok( $marker->exists, 'fetched into it, not re-created' );
  ok( !$perl->check( $t1->{version} ), 'port check: unchanged' );
  is( ts_ok( { op => 'git', action => 'check', opts => \%opts, cached => $p1->{version} } ) ? 1 : 0, 0, 'reference check: unchanged' );

  $repo->{commit}->( { 'skills/a/SKILL.md' => "two\n" }, 'second' );
  ok( $perl->check( $p1->{version} ), 'port sees the move' );
  is( ts_ok( { op => 'git', action => 'check', opts => \%opts, cached => $p1->{version} } ) ? 1 : 0, 1, 'so does the reference' );
  my $p2 = $perl->resolve;
  my $t2 = ts_ok( { op => 'git', action => 'resolve', opts => \%opts } );
  is_deeply( $t2, $p2, 'the reference serves the port\'s update' );
  is( path( $p2->{dir}, 'skills/a/SKILL.md' )->slurp, "two\n", 'content' );

  $repo->{gone}->();
  my $p3 = $perl->resolve;
  my $t3 = ts_ok( { op => 'git', action => 'resolve', opts => \%opts } );
  is_deeply( $p3, $t3, 'offline: the same fallback, word for word' );
  like( $p3->{warning}, qr/using cache/, 'a warning' );
  is( error_of( sub { $perl->check( $p2->{version} ) } ), ts_err( { op => 'git', action => 'check', opts => \%opts, cached => $p2->{version} } ),
    'offline check: the same error' );
};

subtest 'git: pins, refs and refusals word for word' => sub {
  my $tmp  = tempdir;
  my $repo = bare_remote($tmp);
  my $a = $repo->{commit}->( 'A', 'a' );
  $repo->{tag}->( 'v1', 1 );
  my $b = $repo->{commit}->( 'B', 'b' );
  my $root = $tmp->child('cache')->stringify;
  for my $ref ( $a, substr( $a, 0, 9 ), 'v1', 'main' ) {
    my %opts = ( url => $repo->{url}, ref => $ref, cacheRoot => $root );
    my $t = ts_ok( { op => 'git', action => 'resolve', opts => \%opts } );
    my $p = Skilletor::Source::Git->new( url => $repo->{url}, ref => $ref, cache_root => $root )->resolve;
    is_deeply( $p, $t, 'ref '.$ref );
  }
  # move the full-pin cache to another commit behind both implementations' backs
  my $pin = Skilletor::Source::Git->new( url => $repo->{url}, ref => $a, cache_root => $root );
  git_ok( $pin->cache_dir, 'fetch', '-q', 'origin', 'main' );
  git_ok( $pin->cache_dir, 'reset', '-q', '--hard', 'FETCH_HEAD' );
  $repo->{gone}->();
  is( error_of( sub { $pin->resolve } ), ts_err( { op => 'git', action => 'resolve', opts => { url => $repo->{url}, ref => $a, cacheRoot => $root } } ),
    'refused pin cache: the same message' );
  my $nowhere = 'file://'.$tmp->child('nowhere.git');
  is( error_of( sub { Skilletor::Source::Git->new( url => $nowhere, cache_root => $root )->resolve } ),
    ts_err( { op => 'git', action => 'resolve', opts => { url => $nowhere, cacheRoot => $root } } ), 'no cache, no remote' );
  my $opt = '--upload-pack=touch '.$tmp->child('x');
  is( error_of( sub { Skilletor::Source::Git->new( url => $opt, cache_root => $root )->check('git:abc') } ),
    ts_err( { op => 'git', action => 'check', opts => { url => $opt, cacheRoot => $root }, cached => 'git:abc' } ), 'an option-shaped address' );
};

my $srv = serve_http();

# Two trees as name => [ executable, bytes ].
sub tree_of {
  my ( $chars ) = @_;
  my $dir = Skilletor::FSUtil::encode_text($chars);    # readdir gives bytes: walk in bytes
  my %t;
  path($dir)->visit( sub {
    my ( $p ) = @_;
    my $rel = $p->relative($dir)->stringify;
    $t{$rel} = -d $p ? ['dir'] : [ ( -x $p ? 'x' : '-' ), $p->slurp_raw ];
  }, { recurse => 1 } );
  return \%t;
}

subtest 'url: the same tree, version and messages' => sub {
  my @archives = (
    [ 'github-style' => make_tar(
      { name => 'repo-main/', type => '5' },
      { name => 'repo-main/skills/a/SKILL.md', data => "a\n" },
      { name => 'repo-main/skills/a/run.sh', data => "#!/bin/sh\n", mode => 0755 },
      { name => 'repo-main/odd/', type => '5', mode => 0700 },
      { name => 'repo-main/.skilletor-version', data => 'forged' },
    ) ],
    [ 'dot-prefixed' => make_tar( { name => './', type => '5' }, { name => './skills/x/SKILL.md', data => 'x' }, { name => './README.md', data => 'r' } ) ],
    [ 'long names and pax' => make_tar(
      { name => '././@LongLink', type => 'L', data => 'top/'.( 'n' x 120 )."\0" },
      { name => 'cut', data => 'long' },
      pax_path("top/\x{c3}\x{a9}t\x{c3}\x{a9}.md"),
      { name => 'cut2', data => 'pax' },
      { name => 'z.md', prefix => 'top/pre', data => 'pre' },
      { name => 'top/dev', type => '3' },
    ) ],
    [ 'flat' => make_tar( { name => 'SKILL.md', data => 'flat' }, { name => 'two', data => '2', mode => 0700 } ) ],
  );
  for my $case (@archives) {
    my ( $label, $tar ) = @$case;
    my $p = '/'.( $label =~ s/\W/_/gr ).'.tgz';
    $srv->route( $p, { headers => { ETag => '"'.$label.'"' }, body => gzip_bytes($tar) } );
    my $tmp = tempdir;
    my $t = ts_ok( { op => 'url', action => 'resolve', opts => { url => $srv->url($p), cacheRoot => $tmp->child('ts')->stringify } } );
    my $u = Skilletor::Source::Url->new( url => $srv->url($p), cache_root => $tmp->child('pl')->stringify, allow_http => 1 )->resolve;
    is( $u->{version}, $t->{version}, $label.': version' );
    is( path( $u->{dir} )->basename, path( $t->{dir} )->basename, $label.': cache dir name' );
    is_deeply( tree_of( $u->{dir} ), tree_of( $t->{dir} ), $label.': the same tree, bytes and x bits' );
  }

  # one cache root: the reference made it, the port gets a 304 for it, and back
  my $tmp  = tempdir;
  my $root = $tmp->child('cache')->stringify;
  $srv->route( '/shared.tgz', { headers => { ETag => '"s1"' }, body => gzip_bytes( $archives[0][1] ), status_for => { '"s1"' => 304 } } );
  my $t = ts_ok( { op => 'url', action => 'resolve', opts => { url => $srv->url('/shared.tgz'), cacheRoot => $root } } );
  my $perl = Skilletor::Source::Url->new( url => $srv->url('/shared.tgz'), cache_root => $root, allow_http => 1 );
  is_deeply( $perl->resolve, $t, 'the port serves the reference\'s url cache' );
  is( $srv->requests->[-1]{headers}{'if-none-match'}, '"s1"', 'conditionally, with the reference\'s ETag' );

  is_deeply( ts_ok( { op => 'url', action => 'resolve', opts => { url => $srv->url('/shared.tgz'), cacheRoot => $root } } ), $t,
    'and the reference, conditionally again, the same' );
  my %h_pl = %{ $srv->requests->[-2]{headers} };
  my %h_ts = %{ $srv->requests->[-1]{headers} };
  delete @h_ts{qw( host connection )};
  delete @h_pl{qw( host connection te )};
  is_deeply( \%h_pl, \%h_ts, 'the same request headers' );

  for my $fail ( [ 500 => { status => 500 } ], [ 'not gzip' => { body => 'plain', headers => { ETag => '"bad"' } } ],
    [ 'truncated' => { body => substr( gzip_bytes( $archives[0][1] ), 0, 40 ), headers => { ETag => '"tr"' } } ],
    ( map { [ 'size '.$_ => { body => gzip_bytes( make_tar( { name => 'bad', size => $_, data => '' }, { name => 'x', data => 'x' } ) ), headers => { ETag => '"sz"' } } ] }
      '-0000001000', '-1', 'zz' ) ) {
    $srv->route( '/shared.tgz', $fail->[1] );
    is_deeply( $perl->resolve, ts_ok( { op => 'url', action => 'resolve', opts => { url => $srv->url('/shared.tgz'), cacheRoot => $root } } ),
      'fallback on '.$fail->[0].': the same warning' );
  }
  $srv->route( '/unsafe.tgz', { body => gzip_bytes( make_tar( { name => 'a/../../x', data => 'x' } ) ) } );
  is( error_of( sub { Skilletor::Source::Url->new( url => $srv->url('/unsafe.tgz'), cache_root => $root, allow_http => 1 )->resolve } ),
    ts_err( { op => 'url', action => 'resolve', opts => { url => $srv->url('/unsafe.tgz'), cacheRoot => $root } } ), 'unsafe archive: the same error' );
  $srv->route( '/corrupt.tgz', { body => gzip_bytes( make_tar( { name => 'bad', size => '-1', data => '' } ) ) } );
  my $fresh = $tmp->child('fresh')->stringify;
  is( error_of( sub { Skilletor::Source::Url->new( url => $srv->url('/corrupt.tgz'), cache_root => $fresh, allow_http => 1 )->resolve } ),
    ts_err( { op => 'url', action => 'resolve', opts => { url => $srv->url('/corrupt.tgz'), cacheRoot => $fresh } } ), 'corrupt size, no cache: the same error' );
  my $dead = 'http://127.0.0.1:1/x.tgz';
  is( error_of( sub { Skilletor::Source::Url->new( url => $dead, cache_root => $root, allow_http => 1 )->resolve } ),
    ts_err( { op => 'url', action => 'resolve', opts => { url => $dead, cacheRoot => $root } } ), 'refused connection: the same error' );
  $srv->route( '/shared.tgz', { headers => { ETag => '"s9"' } } );
  for my $v ( 'etag:"s9"', 'etag:"s1"', 'sha256:x', undef ) {
    is( $perl->check($v) ? 1 : 0, ts_ok( { op => 'url', action => 'check', opts => { url => $srv->url('/shared.tgz'), cacheRoot => $root }, cached => $v } ) ? 1 : 0,
      'check '.( $v // 'undef' ) );
  }
};

subtest 'sweeps leave what the other implementation would' => sub {
  my $root = tempdir;
  my $make = sub {
    path( $root, '0123456789abcdef.stage-AbC123', 'x' )->touchpath;
    path( $root, 'fedcba9876543210.backup-Zz9Yy8', 'tree', 'kept' )->touchpath;
    path( $root, '1111111111111111', '.git', 'index.lock' )->touchpath;
    utime time - 600, time - 600, "$root/1111111111111111/.git/index.lock";
  };
  $make->();
  ts_ok( { op => 'sweep', root => "$root" } );
  my $after_ts = tree_of("$root");
  $root->remove_tree( { keep_root => 1 } );
  $make->();
  Skilletor::Source::Url->sweep_cache("$root");
  Skilletor::Source::Git->sweep_cache("$root");
  is_deeply( tree_of("$root"), $after_ts, 'same result' );
};

$srv->stop;
done_testing;
