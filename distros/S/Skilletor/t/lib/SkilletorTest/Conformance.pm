package SkilletorTest::Conformance;
# ABSTRACT: A shared conformance case set up on a temp machine, as conformance/README.md says

# The environment of one case – HOME, the project, the git sources and their git config – built
# the way t/60-conformance.t and test/conformance.test.ts build it, so an engine run there
# sees what the case pins. A test can set one case up more than once (each in its own temp dir):
# the commits are made with a fixed identity and date, so every copy has the same SHAs.

use strict;
use warnings;

use Cwd ();
use Exporter qw( import );
use Path::Tiny qw( path tempdir );
use SkilletorTest qw( git_ok );
use Skilletor::FSUtil qw( encode_text read_text );
use Skilletor::JSON qw( js_parse );

our @EXPORT_OK = qw( case_names read_case setup_case with_case_env abstract );

my $ROOT = path(__FILE__)->absolute->parent(4)->child( 'conformance', 'cases' );    # t/lib/SkilletorTest/ -> the checkout

# The commit identity and date every source commit is made with (README: git sources).
my %COMMIT_ENV = (
  GIT_AUTHOR_NAME     => 'skilletor-conformance',
  GIT_AUTHOR_EMAIL    => 'conformance@skilletor.invalid',
  GIT_AUTHOR_DATE     => '2026-01-01T00:00:00+0000',
  GIT_COMMITTER_NAME  => 'skilletor-conformance',
  GIT_COMMITTER_EMAIL => 'conformance@skilletor.invalid',
  GIT_COMMITTER_DATE  => '2026-01-01T00:00:00+0000',
);

# What a case's engine run must not see of the test's own environment (README: environment).
my @UNSET = qw( CODEX_HOME HERMES_HOME CLAUDE_PLUGIN_ROOT CLAUDE_CONFIG_DIR );

sub case_names {
  return () unless $ROOT->is_dir;
  return sort grep { -f "$ROOT/$_/case.json" } map { $_->basename } $ROOT->children;
}

sub read_case {
  my ( $name ) = @_;
  return js_parse( read_text("$ROOT/$name/case.json") );
}

# Every file under $dir, relative and /-separated, sorted.
sub _walk {
  my ( $dir, $base ) = @_;
  $base //= $dir;
  return () unless -d $dir;
  opendir( my $dh, $dir ) or die "opendir $dir: $!";
  my @entries = sort grep { $_ ne '.' && $_ ne '..' } readdir $dh;
  closedir $dh;
  my @out;
  for my $entry (@entries) {
    my $p = "$dir/$entry";
    push @out, -d $p ? _walk( $p, $base ) : substr( $p, length($base) + 1 );
  }
  return sort @out;
}

sub _placeholders {
  my ( $r ) = @_;
  return ( [ $r->{home}, '${HOME}' ], ( $r->{project} ? [ $r->{project}, '${PROJECT}' ] : () ), [ $r->{tmp}, '${TMP}' ] );
}

# Every temp path in $text as its placeholder: HOME first, then PROJECT, then TMP (README: outputs).
sub abstract {
  my ( $text, $r ) = @_;
  $text =~ s/\Q$_->[0]\E/$_->[1]/g for _placeholders($r);
  return $text;
}

sub _concrete {
  my ( $text, $r ) = @_;
  $text =~ s/\Q$_->[1]\E/$_->[0]/g for _placeholders($r);
  return $text;
}

# README: escaped names (`dot.gitignore` is a fixture's `.gitignore`).
sub _unescape { join q{/}, map { /\Adot\.git/ ? substr( $_, 3 ) : $_ } split m{/}, $_[0], -1 }

sub _copy_input {
  my ( $from, $to, $r ) = @_;
  for my $rel ( _walk($from) ) {
    my $dest = path( $to, _unescape($rel) );
    $dest->parent->mkpath;
    $dest->spew_raw( encode_text( _concrete( read_text("$from/$rel"), $r ) ) );
  }
}

sub _copy_tree {
  my ( $from, $to ) = @_;
  for my $rel ( _walk($from) ) {
    my $dest = path( $to, _unescape($rel) );
    $dest->parent->mkpath;
    path( $from, $rel )->copy($dest);
    chmod( ( stat "$from/$rel" )[2] & 07777, "$dest" );
  }
}

sub _build_git {
  my ( $case_dir, $c, $r ) = @_;
  local @ENV{ keys %COMMIT_ENV } = values %COMMIT_ENV;
  my @config;
  my $git = $c->{git} // {};
  for my $name ( keys %$git ) {
    my $g    = $git->{$name};
    my $repo = path( $r->{tmp}, 'git', $name );
    $repo->mkpath;
    git_ok( "$repo", 'init', '-q', '-b', 'main' );
    my $i = 0;
    for my $commit ( @{ $g->{commits} } ) {
      $i++;
      $_->basename eq '.git' or $_->remove_tree( { safe => 0 } ) for $repo->children;
      _copy_tree( "$case_dir/$commit->{tree}", "$repo" );
      chmod 0755, "$repo/$_" for @{ $commit->{executable} // [] };
      git_ok( "$repo", 'add', '-A' );
      git_ok( "$repo", 'commit', '-q', '--allow-empty', '-m', "conformance $i" );
      git_ok( "$repo", 'tag', $commit->{tag} )       if defined $commit->{tag};
      git_ok( "$repo", 'branch', $commit->{branch} ) if defined $commit->{branch};
    }
    push @config, '[url "file://'.$repo.'"]', "\tinsteadOf = ".$g->{url};
  }
  path( $r->{tmp}, 'gitconfig' )->spew_raw( encode_text( join( "\n", @config )."\n" ) );
}

# Run $code with the case's environment: its git config, nothing of @UNSET, the case's `env`.
sub with_case_env {
  my ( $r, $code ) = @_;
  local @ENV{ @UNSET, keys %{ $r->{env} } };
  delete @ENV{@UNSET};
  $ENV{$_} = defined $r->{env}{$_} ? encode_text( $r->{env}{$_} ) : undef for keys %{ $r->{env} };
  return $code->();
}

# A fresh temp machine for case $name: { tmp, home, project?, env }; the temp dir lives as long
# as the returned hash.
sub setup_case {
  my ( $name ) = @_;
  my $case_dir = "$ROOT/$name";
  my $c = read_case($name);
  my $tempdir = tempdir( 'skilletor-conformance-XXXXXX', TMPDIR => 1 );
  my $tmp = Cwd::realpath("$tempdir");
  my $r = { tempdir => $tempdir, tmp => $tmp, home => "$tmp/home" };
  $r->{project} = "$tmp/project" if -d "$case_dir/project";
  $r->{env} = { GIT_CONFIG_GLOBAL => "$tmp/gitconfig", GIT_CONFIG_NOSYSTEM => '1' };
  $r->{env}{$_} = _concrete( $c->{env}{$_}, $r ) for keys %{ $c->{env} // {} };
  with_case_env(
    $r,
    sub {
      _build_git( $case_dir, $c, $r );
      path( $r->{home}, '.claude' )->mkpath;
      my $marker = !( exists $c->{claude} && !$c->{claude} );    # "claude": false – no marker, Claude Code is not in use
      path( $r->{home}, '.claude.json' )->spew_raw("{}\n") if $marker;    # Claude Code is in use (spec §14.1)
      if ( defined $ENV{CLAUDE_CONFIG_DIR} ) {    # Claude Code keeps its .claude.json inside a custom config dir
        path( $ENV{CLAUDE_CONFIG_DIR} )->mkpath;
        path( $ENV{CLAUDE_CONFIG_DIR}, '.claude.json' )->spew_raw("{}\n") if $marker;
      }
      _copy_input( "$case_dir/home", $r->{home}, $r );
      if ( $r->{project} ) {
        path( $r->{project} )->mkpath;
        _copy_input( "$case_dir/project", $r->{project}, $r );
      }
      for my $where ( @{ $c->{gitInit} // [] } ) {    # the work trees the case asks for
        my $dir = ( $where eq 'home' || $where eq 'project' ? $r->{$where} : undef )
          // die "$name: gitInit names $where, which this case does not have\n";
        git_ok( $dir, 'init', '-q', '-b', 'main' );
      }
    }
  );
  return $r;
}

1;
