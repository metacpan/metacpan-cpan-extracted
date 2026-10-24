#!/usr/bin/env perl
# The Perl runner of the shared conformance cases (../conformance, k143): the format is
# ../conformance/README.md, the reference runner ../test/conformance.test.ts. Every case runs in
# a fresh temp dir – HOME, the project, the git sources and a git config of its own – exactly as
# the reference runner sets it up, so both engines build the same commits and cache dir names.
use strict;
use warnings;
use Test::More;
use FindBin;
use lib "$FindBin::Bin/lib";
use SkilletorTest qw( git_ok );

use Cwd ();
use JSON::MaybeXS ();
use Path::Tiny qw( path tempdir );
use Skilletor::FSUtil qw( encode_text read_text );
use Skilletor::JSON qw( js_parse js_sort_keys js_stringify js_type );
use Skilletor::Engine;

my $ROOT = path( $FindBin::Bin, '..', '..', 'conformance', 'cases' );
plan skip_all => 'needs the shared conformance cases (../conformance, a skilletor checkout)' unless $ROOT->is_dir;

# The commit identity and date every source commit is made with (README: git sources).
my %COMMIT_ENV = (
  GIT_AUTHOR_NAME     => 'skilletor-conformance',
  GIT_AUTHOR_EMAIL    => 'conformance@skilletor.invalid',
  GIT_AUTHOR_DATE     => '2026-01-01T00:00:00+0000',
  GIT_COMMITTER_NAME  => 'skilletor-conformance',
  GIT_COMMITTER_EMAIL => 'conformance@skilletor.invalid',
  GIT_COMMITTER_DATE  => '2026-01-01T00:00:00+0000',
);

# Every file under $dir, relative and /-separated, sorted; $skip holds relative paths left out.
sub walk {
  my ( $dir, $skip, $base ) = @_;
  $skip //= [];
  $base //= $dir;
  return () unless -d $dir;
  my @out;
  opendir( my $dh, $dir ) or die "opendir $dir: $!";
  my @entries = sort grep { $_ ne '.' && $_ ne '..' } readdir $dh;
  closedir $dh;
  for my $entry (@entries) {
    my $p   = "$dir/$entry";
    my $rel = substr $p, length($base) + 1;
    next if grep { $_ eq $rel } @$skip;
    if   ( -d $p ) { push @out, walk( $p, $skip, $base ) }
    else           { push @out, $rel }
  }
  return sort @out;
}

# Keys sorted, arrays sorted by the canonical text of their elements, recursively (README).
sub canonical {
  my ( $v ) = @_;
  my $type = js_type($v);
  if ( $type eq 'array' ) {
    my %by;
    my @texts = map { my $c = canonical($_); my $t = js_stringify($c); $by{$t} = $c; $t } @$v;
    return [ map { $by{$_} } js_sort_keys(@texts) ];
  }
  return { map { ( $_ => canonical( $v->{$_} ) ) } keys %$v } if $type eq 'object';
  return $v;
}

# The projection of a resolve the cases pin (README: resolve).
sub resolve_view {
  my ( $r ) = @_;
  return { error => $r->{error}, scopes => [] } if defined $r->{error};
  return {
    scopes => [
      map {
        my $s = $_;
        +{
          scope   => $s->{scope},
          sources => [
            map {
              my $src = $_;
              my %o = ( name => $src->{name}, state => $src->{state} );
              if ( my $b = $src->{backend} ) {
                @o{qw( kind address origin )} = @{$b}{qw( kind address origin )};
                $o{ref}  = $b->{ref}  if defined $b->{ref};
                $o{path} = $b->{path} if defined $b->{path};
              }
              defined $src->{$_} and $o{$_} = $src->{$_} for qw( cache dir version );
              \%o;
            } @{ $s->{sources} }
          ],
          items => [
            map {
              my $i = $_;
              my %o = (
                type       => $i->{type},
                name       => $i->{name},
                source     => $i->{source},
                declaredBy => $i->{declaredBy},
                path       => $i->{type} eq 'skill' ? $i->{item}{dir} : $i->{item}{files}[0],
                files      => $i->{item}{files},
                templated  => ( grep { /\.njk\z/ } @{ $i->{item}{files} } ) ? JSON::MaybeXS::true() : JSON::MaybeXS::false(),
                vars       => $i->{vars},
              );
              $o{via}         = $i->{via}               if $i->{via};
              $o{description} = $i->{item}{description} if defined $i->{item}{description};
              \%o;
            } @{ $s->{items} }
          ],
          warnings      => $s->{warnings},
          trustRequests => $s->{trustRequests},
        };
      } @{ $r->{scopes} }
    ],
  };
}

sub placeholders {
  my ( $r ) = @_;
  return ( [ $r->{home}, '${HOME}' ], ( $r->{project} ? [ $r->{project}, '${PROJECT}' ] : () ), [ $r->{tmp}, '${TMP}' ] );
}

sub abstract {
  my ( $text, $r ) = @_;
  $text =~ s/\Q$_->[0]\E/$_->[1]/g for placeholders($r);
  return $text;
}

sub concrete {
  my ( $text, $r ) = @_;
  $text =~ s/\Q$_->[1]\E/$_->[0]/g for placeholders($r);
  return $text;
}

# A path as a case stores it (README: escaped names): every name starting with `.git` gets the
# prefix `dot`, since a `.gitignore` in a fixture would be live in the repository.
sub escape_name   { join q{/}, map { /\A\.git/ ? "dot$_" : $_ } split m{/}, $_[0], -1 }
sub unescape_name { join q{/}, map { /\Adot\.git/ ? substr( $_, 3 ) : $_ } split m{/}, $_[0], -1 }

# Copy a case's input tree, placeholders substituted in every file (README: inputs).
sub copy_input {
  my ( $from, $to, $r ) = @_;
  for my $rel ( walk($from) ) {
    my $dest = path( $to, unescape_name($rel) );
    $dest->parent->mkpath;
    $dest->spew_raw( encode_text( concrete( read_text("$from/$rel"), $r ) ) );
  }
}

# Copy a source tree byte for byte, modes kept (cpSync).
sub copy_tree {
  my ( $from, $to ) = @_;
  for my $rel ( walk($from) ) {
    my $dest = path( $to, unescape_name($rel) );
    $dest->parent->mkpath;
    path( $from, $rel )->copy($dest);
    chmod( ( stat "$from/$rel" )[2] & 07777, "$dest" );
  }
}

# Build the case's git sources and the git config that reaches them (README: git sources).
sub build_git {
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
      copy_tree( "$case_dir/$commit->{tree}", "$repo" );
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

# The files a tree step compares (README: trees): HOME but the state dir and the marker, all of PROJECT.
sub snapshot {
  my ( $r ) = @_;
  my %out;
  $out{ "home/".escape_name($_) } = abstract( read_text("$r->{home}/$_"), $r ) for walk( $r->{home}, [ '.claude/skilletor', '.claude.json' ] );
  if ( $r->{project} ) {
    $out{ "project/".escape_name($_) } = abstract( read_text("$r->{project}/$_"), $r ) for walk( $r->{project} );
  }
  return \%out;
}

sub run_case {
  my ( $name ) = @_;
  my $case_dir = "$ROOT/$name";
  my $c = js_parse( read_text("$case_dir/case.json") );
  my @live = grep { grep { /\A\.git/ } split m{/} } walk($case_dir);
  is_deeply( \@live, [], 'fixture names starting with .git are stored escaped (dot.gitignore)' );
  my $engine = ( $c->{engines} // {} )->{perl} // {};
  plan skip_all => $engine->{skip} if defined $engine->{skip};
  my $tempdir = tempdir( 'skilletor-conformance-XXXXXX', TMPDIR => 1 );    # removed with the case
  my $tmp = Cwd::realpath("$tempdir");
  my $r = { tmp => $tmp, home => "$tmp/home" };
  $r->{project} = "$tmp/project" if -d "$case_dir/project";

  local $ENV{GIT_CONFIG_GLOBAL}   = "$tmp/gitconfig";
  local $ENV{GIT_CONFIG_NOSYSTEM} = '1';
  local @ENV{qw( CODEX_HOME HERMES_HOME CLAUDE_PLUGIN_ROOT CLAUDE_CONFIG_DIR )};
  delete @ENV{qw( CODEX_HOME HERMES_HOME CLAUDE_PLUGIN_ROOT CLAUDE_CONFIG_DIR )};
  $ENV{$_} = concrete( $c->{env}{$_}, $r ) for sort keys %{ $c->{env} // {} };
  build_git( $case_dir, $c, $r );
  path( $r->{home}, '.claude' )->mkpath;
  path( $r->{home}, '.claude.json' )->spew_raw("{}\n");    # Claude Code is in use (spec §14.1)
  if ( defined $ENV{CLAUDE_CONFIG_DIR} ) {    # Claude Code keeps its .claude.json inside a custom config dir
    path( $ENV{CLAUDE_CONFIG_DIR} )->mkpath;
    path( $ENV{CLAUDE_CONFIG_DIR}, '.claude.json' )->spew_raw("{}\n");
  }
  copy_input( "$case_dir/home", $r->{home}, $r );
  if ( $r->{project} ) {
    path( $r->{project} )->mkpath;
    copy_input( "$case_dir/project", $r->{project}, $r );
  }
  my $sk = Skilletor::Engine->new(
    home             => $r->{home},
    ( $r->{project} ? ( project_dir => $r->{project} ) : () ),
    state_root       => "$r->{home}/.claude/skilletor",
    codex_home       => "$r->{home}/.codex",
    require_harness  => 1,              # the reference's resolve: a machine without a harness is an error
    is_git_work_tree => sub { 0 },      # neither dir lies in a work tree, git tracks none of their files
    git_tracked      => sub { [] },
  );

  for my $step ( @{ $c->{steps} } ) {
    my $id = $step->{id};
    my $variant = ( $engine->{steps} // {} )->{$id} // {};
    if ( defined $variant->{skip} ) {
      pass( "step $id skipped: $variant->{skip}" );
      next;
    }
    my $expected = defined $variant->{expected} ? "$case_dir/$variant->{expected}" : "$case_dir/expected/$id";
    my %opts = ( scope => $step->{scope} // 'all' );
    my $result =
        $step->{op} eq 'resolve' ? resolve_view( $sk->resolve(%opts) )
      : $step->{op} eq 'sync'    ? $sk->sync( %opts, force => $step->{force} ? 1 : 0 )
      : $step->{op} eq 'check'   ? $sk->check(%opts)
      : $step->{op} eq 'status'  ? $sk->status(%opts)
      :                            die "unknown op $step->{op}";
    my $actual = canonical( js_parse( abstract( js_stringify($result), $r ) ) );
    my $want   = canonical( js_parse( read_text("$expected.json") ) );
    is( js_stringify( $actual, 2 ), js_stringify( $want, 2 ), "step $id" );
    next unless $step->{tree};
    my $have  = snapshot($r);
    my %want  = map { ( $_ => read_text("$expected/$_") ) } walk($expected);
    is_deeply( [ sort keys %$have ], [ sort keys %want ], "step $id: the files in the tree" );
    is( $have->{$_}, $want{$_}, "step $id: $_" ) for sort keys %want;
    my @execs = grep {
      my ( $where, $rel ) = unescape_name($_) =~ m{\A(home|project)/(.*)\z}s;
      ( ( stat( $r->{$where}.'/'.$rel ) )[2] // 0 ) & 0100;
    } sort keys %$have;
    my $want_execs = -f "$expected.executables.json" ? js_parse( read_text("$expected.executables.json") ) : [];
    is_deeply( \@execs, [@$want_execs], "step $id: the files with the executable bit" );
  }
}

my @cases = sort grep { -f "$ROOT/$_/case.json" } map { $_->basename } $ROOT->children;
ok( scalar @cases, 'the cases directory holds cases' );
for my $name (@cases) {
  subtest "conformance: $name" => sub { run_case($name) };
}

done_testing;
