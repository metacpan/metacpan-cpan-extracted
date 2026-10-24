package Skilletor::Source::Git;
# ABSTRACT: A git source: shallow fetch into the shared cache, refs, SHA pins, offline reuse

use Moo;
use Path::Tiny qw( path );
use Scalar::Util qw( blessed );
use Skilletor::Cache qw( git_cache_dir CACHE_NAME_RE );
use Skilletor::Error::CacheRejected;
use Skilletor::Error::Source;
use Skilletor::FSUtil qw( decode_utf8_lossy path_join path_resolve );
use Skilletor::GitEnv qw( git_env );
use Skilletor::JSString qw( js_lc js_trim );
use Skilletor::Process qw( run_command );
use Time::HiRes ();
use namespace::clean;

with 'Skilletor::Role::Source';

our $VERSION = '0.001';

# Git for Windows checks out with core.autocrlf=true; the cache holds the repository's bytes
# there as everywhere, and longpaths lifts the 260-character limit.
my @CHECKOUT_AS_IS = $^O eq 'MSWin32' ? ( '-c', 'core.autocrlf=false', '-c', 'core.eol=lf', '-c', 'core.longpaths=true' ) : ();

# The fetch refspec `git remote add` gives origin.
my $ORIGIN_REFSPEC = '+refs/heads/*:refs/remotes/origin/*';

# git's order for a short ref name (ref_rev_parse_rules): the ref `git fetch` takes.
my @REF_RULES = (
  sub { $_[0] },                 sub { 'refs/'.$_[0] },
  sub { 'refs/tags/'.$_[0] },    sub { 'refs/heads/'.$_[0] },
  sub { 'refs/remotes/'.$_[0] }, sub { 'refs/remotes/'.$_[0].'/HEAD' },
);

# The lock files, relative to .git, that git takes for what resolve runs.
my @LOCK_FILES = ( 'index.lock', 'shallow.lock', 'config.lock', 'HEAD.lock', 'ORIG_HEAD.lock', 'packed-refs.lock', 'reftable/tables.list.lock' );

# How old a lock file must be to count as a dead git's: the sync lock's stale age.
my $STALE_LOCK_SECONDS = 5 * 60;

has url => (
  is       => 'ro',
  required => 1,
);

has ref => (
  is => 'ro',
);

has cache_root => (
  is       => 'ro',
  required => 1,
);

has timeout_ms => (
  is      => 'ro',
  default => sub { 60_000 },
);

sub cache_dir {
  my ( $self ) = @_;
  return git_cache_dir( $self->cache_root, $self->url, $self->ref );
}

sub is_commitish {
  my ( $self, $ref ) = @_;
  return ( defined $ref && $ref =~ /\A[0-9a-f]{7,40}\z/i ) ? 1 : 0;
}

sub _pinned { my ( $self ) = @_; my $ref = $self->ref; return ( defined $ref && length $ref && $self->is_commitish($ref) ) ? 1 : 0 }

# One git run: no shell, the repository-local variables dropped, never a repository above the
# cache. Fails with git's stderr – or Node's "Command failed: …" when git wrote none.
sub _run {
  my ( $self, $cwd, $args, $timeout_ms, $env ) = @_;
  my @cmd = ( 'git', @CHECKOUT_AS_IS, @$args );
  my %extra = ( ( length( $cwd // '' ) ? ( GIT_CEILING_DIRECTORIES => path_resolve( $cwd, '..' ) ) : () ), %{ $env // {} } );
  my $r = run_command(
    cmd        => \@cmd,
    cwd        => ( length( $cwd // '' ) ? $cwd : undef ),
    env        => git_env(%extra),
    timeout_ms => $timeout_ms // $self->timeout_ms,
  );
  my $what = 'git '.join( ' ', @$args );
  if ( my $spawn = $r->{spawn_error} ) {
    Skilletor::Error::Source->throw( $what.': spawn git '.( $spawn->{errno} == 2 ? 'ENOENT' : $spawn->{message} ) );
  }
  if ( $r->{timed_out} || !defined $r->{code} || $r->{code} != 0 ) {
    my $stderr = js_trim( decode_utf8_lossy( $r->{stderr} ) );
    Skilletor::Error::Source->throw( $what.': '.( length $stderr ? $stderr : 'Command failed: '.join( ' ', @cmd ) ) );
  }
  return decode_utf8_lossy( $r->{stdout} );
}

sub _ok {
  my ( $self, @args ) = @_;
  my $out;
  return eval { $out = $self->_run(@args); 1 } ? ( 1, $out ) : ( 0, $@ );
}

sub _msg { my ( $err ) = @_; return blessed $err && $err->can('message') ? $err->message : js_trim("$err") }

sub _is_repo { -e path_join( $_[1], '.git' ) ? 1 : 0 }

sub resolve {
  my ( $self ) = @_;
  my $dir = $self->cache_dir;
  my $ref = $self->ref;
  my $result = eval {
    if ( !$self->_is_repo($dir) ) {
      path($dir)->mkpath;
      $self->_run( $dir, [ 'init', '-q' ] );
      $self->_run( $dir, [ 'remote', 'add', '--', 'origin', $self->url ] );
    }
    else {
      $self->_repair($dir);
    }
    my $reset_target = 'FETCH_HEAD';
    if ( $self->_pinned ) {
      my ($fetched) = $self->_ok( $dir, [ 'fetch', '--depth', '1', '--', 'origin', $ref ] );
      unless ($fetched) {
        $self->_run( $dir, [ 'fetch', 'origin' ] );
        $reset_target = $ref;
      }
    }
    else {
      $self->_run( $dir, [ 'fetch', '--depth', '1', '--', 'origin', ( defined $ref ? $ref : 'HEAD' ) ] );
    }
    $self->_run( $dir, [ 'reset', '--hard', $reset_target ] );
    # reset --hard leaves every file its index does not track.
    $self->_run( $dir, [ 'clean', '-ffdxq' ] );
    +{ dir => $dir, version => $self->_version($dir) };
  };
  return $result if $result;
  my $err = _msg($@);
  if ( $self->_is_repo($dir) ) {
    my $served = eval {
      my $version = $self->_version($dir);
      $self->_restore($dir);
      +{ dir => $dir, version => $version, warning => 'git fetch failed for '.$self->url.', using cache ('.$err.')' };
    };
    return $served if $served;
    my $cache_error = $@;
    # A repo without a commit is no cache; only a refused pin or checkout is worth naming.
    if ( blessed $cache_error && $cache_error->isa('Skilletor::Error::CacheRejected') ) {
      Skilletor::Error::Source->throw( 'git source '.$self->url.' failed: '.$err.'; cache rejected ('.$cache_error->message.')' );
    }
  }
  Skilletor::Error::Source->throw( 'git source '.$self->url.' failed: '.$err );
}

# The cache as it is, without the network: what resolve serves when a fetch fails, without the
# warning – the checkout brought back to its HEAD, a pin checked against it.
sub cached {
  my ( $self ) = @_;
  my $dir = $self->cache_dir;
  Skilletor::Error::Source->throw( 'git source '.$self->url.' is not in the cache (no fetch)' ) unless $self->_is_repo($dir);
  my $served = eval {
    my $version = $self->_version($dir);
    $self->_restore($dir);
    +{ dir => $dir, version => $version };
  };
  return $served if $served;
  my $err = $@;
  if ( blessed $err && $err->isa('Skilletor::Error::CacheRejected') ) {
    Skilletor::Error::Source->throw( 'git source '.$self->url.': cache rejected ('.$err->message.')' );
  }
  Skilletor::Error::Source->throw( 'git source '.$self->url.' is not in the cache (no fetch; '._msg($err).')' );
}

# Make a cache a killed run left half-made fit to fetch into, keeping what it holds.
sub _repair {
  my ( $self, $dir ) = @_;
  my ( $ok, $out ) = $self->_ok( $dir, [ 'config', '--local', '-z', '--get-regexp', '^remote\\.origin\\.(url|fetch)$' ] );
  my %origin = $ok ? %{ $self->_config_entries($out) } : ();
  unless ( exists $origin{'remote.origin.url'} ) {
    $self->_run( $dir, [ 'init', '-q' ] );
    $self->_run( $dir, [ 'remote', 'add', '--', 'origin', $self->url ] );
    return;
  }
  $self->_run( $dir, [ 'remote', 'set-url', '--', 'origin', $self->url ] ) if $origin{'remote.origin.url'} ne $self->url;
  $self->_run( $dir, [ 'config', '--local', 'remote.origin.fetch', $ORIGIN_REFSPEC ] ) unless exists $origin{'remote.origin.fetch'};
}

# Bring the checkout of a cache about to be served offline back to exactly its HEAD commit.
sub _restore {
  my ( $self, $dir ) = @_;
  my ( $ok, $out ) = $self->_ok( $dir, [ 'status', '--porcelain', '--ignored', '--untracked-files=normal' ], undef, { GIT_OPTIONAL_LOCKS => '0' } );
  return if $ok && $out eq '';
  my $fixed = eval {
    $self->_run( $dir, [ 'reset', '--hard', 'HEAD' ] );
    $self->_run( $dir, [ 'clean', '-ffdxq' ] );
    1;
  };
  return if $fixed;
  Skilletor::Error::CacheRejected->throw( 'its checkout cannot be brought back to HEAD: '._msg($@) );
}

sub _version {
  my ( $self, $dir ) = @_;
  my $ref = $self->ref;
  if ( $self->_pinned ) {
    # Validate even on fallback: a repo's existence is no proof it holds this pin.
    my $head = js_trim( $self->_run( $dir, [ 'rev-parse', '--verify', 'HEAD^{commit}' ] ) );
    my ( $ok, $out ) = $self->_ok( $dir, [ 'rev-parse', '--verify', '--quiet', $ref.'^{commit}' ] );
    my $pin = $ok ? js_trim($out) : '';
    # A prefix of HEAD must resolve to HEAD unambiguously; any other ref is taken as a name
    # unless it names another commit here – or is a full SHA, never read as a name.
    my $by_name = length($ref) < 40 && ( $pin eq '' || $pin eq $head );
    my $held = index( $head, js_lc($ref) ) == 0 ? $pin eq $head : $by_name;
    Skilletor::Error::CacheRejected->throw( 'cached commit '.$head.' does not match requested pin '.$ref ) unless $held;
  }
  my $sha = js_trim( $self->_run( $dir, [ 'rev-parse', '--short', 'HEAD' ] ) );
  return 'git:'.$sha;
}

sub check {
  my ( $self, $cached_version ) = @_;
  return 1 unless defined $cached_version && length $cached_version;
  my $ref = $self->ref;
  ( my $cached = $cached_version ) =~ s/\Agit://;
  $cached = js_lc($cached);
  # A SHA pin the lock already holds never moves: decided without the remote.
  return 0 if $self->_pinned && _same_prefix( $cached, js_lc($ref) );
  # The commit the ref names upstream; nothing counts as changed.
  my $name = defined $ref ? $ref : 'HEAD';
  my @patterns = map { ( $_, $_.'^{}' ) } $name, $name.'/HEAD';
  my $out = $self->_run( '', [ 'ls-remote', '--', $self->url, @patterns ], $self->timeout_ms );
  my $remote = $self->remote_commit( $out, $name );
  return ( length $cached && index( $remote, $cached ) == 0 ) ? 0 : 1;
}

# The commit a ref names in `git ls-remote` output: of the refs listed, the one git ranks
# first, through its peeled ^{} line when it is a tag object. "" when none is listed.
sub remote_commit {
  my ( $self, $ls_remote, $ref ) = @_;
  my %shas;
  for my $line ( split /\n/, $ls_remote, -1 ) {
    my ( $sha, $name ) = split /\t/, $line, -1;
    $shas{$name} = js_lc($sha) if defined $sha && length $sha && defined $name && length $name;
  }
  for my $rule (@REF_RULES) {
    my $name = $rule->($ref);
    my $sha = $shas{ $name.'^{}' } // $shas{$name};
    return $sha if defined $sha && length $sha;
  }
  return '';
}

sub _same_prefix {
  my ( $a, $b ) = @_;
  return length $a && length $b && ( index( $a, $b ) == 0 || index( $b, $a ) == 0 );
}

# `git config -z` output – key\nvalue\0 per entry – as key => last value.
sub _config_entries {
  my ( $self, $out ) = @_;
  my %entries;
  for my $entry ( split /\0/, $out, -1 ) {
    next if $entry eq '';
    my $nl = index $entry, "\n";
    $entries{ $nl < 0 ? $entry : substr( $entry, 0, $nl ) } = $nl < 0 ? '' : substr( $entry, $nl + 1 );
  }
  return \%entries;
}

# Remove the lock files a git killed midway left in the git caches of a cache root – each once
# older than the sync lock's stale age. Only safe while no resolve runs: the caller holds the
# sync lock. Never throws.
sub sweep_cache {
  my ( $class, $cache_root, $now ) = @_;
  $now //= Time::HiRes::time();
  opendir( my $dh, $cache_root ) or return;
  my @names = readdir $dh;
  closedir $dh;
  for my $name (@names) {
    next unless $name =~ CACHE_NAME_RE;
    my $git_dir = path_join( $cache_root, $name, '.git' );
    next unless lstat($git_dir) && -d _;    # a symlink or a gitfile: not one git init made
    for my $file ( ( map { path_join( $git_dir, $_ ) } @LOCK_FILES ), $class->_ref_locks( path_join( $git_dir, 'refs' ) ) ) {
      my @st = lstat $file or next;
      next unless -f _;
      unlink $file if $now - $st[9] > $STALE_LOCK_SECONDS;
    }
  }
  return;
}

sub _ref_locks {
  my ( $class, $dir ) = @_;
  opendir( my $dh, $dir ) or return ();
  my @names = grep { $_ ne '.' && $_ ne '..' } readdir $dh;
  closedir $dh;
  my @out;
  for my $name (@names) {
    my $p = path_join( $dir, $name );
    lstat $p or next;
    if    ( -d _ )                      { push @out, $class->_ref_locks($p) }
    elsif ( -f _ && $name =~ /\.lock\z/ ) { push @out, $p }
  }
  return @out;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Skilletor::Source::Git - A git source: shallow fetch into the shared cache, refs, SHA pins, offline reuse

=head1 VERSION

version 0.001

=head1 SYNOPSIS

  use Skilletor::Source::Git;
  use Skilletor::Cache qw( cache_root );

  my $src = Skilletor::Source::Git->new(
    url        => 'https://github.com/Getty/skills',
    ref        => 'main',                 # optional: the remote's HEAD without
    cache_root => cache_root( $ENV{HOME} ),
  );
  my $loc = $src->resolve;     # { dir => '…/cache/d2425b64323b2f4a', version => 'git:ab12cd3' }
  my $moved = $src->check( $loc->{version} );

=head1 DESCRIPTION

The reference's C<sources/git.ts> (spec §4.4), down to the git commands it
runs, so a cache one implementation made the other takes as is.

L</resolve> shallow-fetches into C<< <cache_root>/<16 hex> >> – the directory
named by L<Skilletor::Cache> – and hard-resets to what it fetched: C<ref>, or the
remote's HEAD. A SHA pin that the remote will not hand out shallowly falls back
to a full fetch and a reset to the pin. A cache a killed run left half-made is
repaired first, keeping its objects. Unreachable remote, existing cache: the
cache is served with a warning – after its checkout is brought back to exactly
its HEAD, and, for a SHA pin, only if HEAD is the pin. No cache, or a refused
one: L<Skilletor::Error::Source>.

Every git runs without a shell, with L<Skilletor::GitEnv/git_env> and
C<GIT_CEILING_DIRECTORIES> above the cache; the address and the ref always
follow C<-->. Messages are the reference's, git's stderr included.

=head2 url

The git address, as configured; it reaches git after C<-->.

=head2 ref

A branch, tag or commit; a 7 to 40 digit hex ref is a SHA pin.

=head2 cache_root

Where the caches live (L<Skilletor::Cache/cache_root>).

=head2 timeout_ms

Per git run (default 60000); the child gets C<SIGTERM> after it.

=head2 cache_dir

This source's cache directory (L<Skilletor::Cache/git_cache_dir>).

=head2 resolve

C<< { dir, version => 'git:<short sha>', warning? } >>.

=head2 cached

C<< { dir, version } >> of the cache without touching the network – what
L</resolve> serves when its fetch fails, minus the warning (a Perl addition for
offline callers; the reference has no such call). Throws
L<Skilletor::Error::Source> when there is no cache or it does not hold the
pinned commit.

=head2 check

  $src->check($cached_version);

A SHA pin already in C<$cached_version> is unchanged without asking the remote;
anything else compares the commit C<git ls-remote> names for the ref (git's
own ranking, annotated tags peeled) with the cached one.

=head2 remote_commit

  $src->remote_commit( $ls_remote_output, $ref );

=head2 is_commitish

True for 7 to 40 hex digits: a SHA pin.

=head2 sweep_cache

  Skilletor::Source::Git->sweep_cache($cache_root);

Removes stale git lock files from every git cache; only while holding the
sync lock.

=head1 SUPPORT

=head1 CONTRIBUTING

Contributions are welcome! Please fork the repository and submit a pull request.

=head1 AUTHOR

Torsten Raudssus <getty@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by Torsten Raudssus <torsten@raudssus.de> L<https://raudssus.de/>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
