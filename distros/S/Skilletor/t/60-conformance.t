#!/usr/bin/env perl
# The Perl runner of the shared conformance cases (conformance/, k143): the format is
# conformance/README.md, the reference runner test/conformance.test.ts. Every case runs in
# a fresh temp dir – HOME, the project, the git sources and a git config of its own – exactly as
# the reference runner sets it up, so both engines build the same commits and cache dir names. A
# `cli` step runs a CLI – script/skilletor, or the one SKILLETOR_CONFORMANCE_CLI names (the
# reference's bundle, say) – in an environment built from nothing.
use strict;
use warnings;
use Test::More;
use FindBin;
use lib "$FindBin::Bin/lib";
use SkilletorTest qw( git_ok git_out );
use SkilletorTest::ParityCLI ();

use Cwd ();
use Encode ();
use File::Spec ();
use JSON::MaybeXS ();
use Path::Tiny qw( path tempdir );
use Skilletor::CLI ();
use Skilletor::FSUtil qw( encode_text read_text to_posix );
use Skilletor::JSON qw( js_ordered js_parse js_sort_keys js_stringify js_type );
use Skilletor::Engine;
use Skilletor::Process qw( run_command );

my $ROOT = path( $FindBin::Bin, '..', 'conformance', 'cases' );
plan skip_all => 'needs the shared conformance cases (conformance/, a skilletor checkout)' unless $ROOT->is_dir;

# The version a `cli` step that asks for it writes as ${VERSION} (README: placeholders), in either
# spelling: the plugin's (package.json, 0.8.0), which the reference CLI reports, and the dist's
# ($VERSION, 0.008000), which the Perl CLI reports. t/02-version.t ties the two.
my @VERSIONS = ( js_parse( read_text( path( $FindBin::Bin, '..', 'package.json' ) ) )->{version}, $Skilletor::CLI::VERSION );

# The CLI of `cli` steps as an argv prefix (README: which CLI): SKILLETOR_CONFORMANCE_CLI, a JSON
# array, else this perl running script/skilletor from lib/.
my @CLI = do {
  my $override = $ENV{SKILLETOR_CONFORMANCE_CLI};
  if ( defined $override ) {
    my $prefix = js_parse( Encode::decode( 'UTF-8', $override ) );
    BAIL_OUT("SKILLETOR_CONFORMANCE_CLI is no JSON array of strings: $override")
      unless js_type($prefix) eq 'array' && @$prefix && !grep { js_type($_) ne 'string' } @$prefix;
    map { encode_text($_) } @$prefix;
  }
  else {
    ( $^X, '-I'.path( $FindBin::Bin, '..', 'lib' )->realpath, path( $FindBin::Bin, '..', 'script', 'skilletor' )->realpath."" );
  }
};
my $CLI_TIMEOUT_MS = 30_000;

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

sub _json_string_contents {
  my ( $value ) = @_;
  return substr( js_stringify($value), 1, -1 );
}

sub _in_json_string {
  my ( $text, $offset ) = @_;
  my ( $quoted, $escaped ) = ( 0, 0 );
  for my $i ( 0 .. $offset - 1 ) {
    my $c = substr( $text, $i, 1 );
    if    ($escaped)     { $escaped = 0 }
    elsif ( $c eq '\\' ) { $escaped = 1 }
    elsif ( $c eq '"' )  { $quoted = !$quoted }
  }
  return $quoted;
}

sub _nested_json_intervals {
  my ( $text ) = @_;
  my ( @intervals, @tokens );
  my $outer = 0;
  my $finish_outer = sub {
    for ( my $i = 0; $i + 1 < @tokens; ) {
      my ( $open, $close ) = @tokens[ $i, $i + 1 ];
      my $before = $open->{slash} > 0 ? substr( $text, $open->{slash} - 1, 1 ) : '';
      my $after = substr( $text, $close->{quote} + 1, 1 );
      my $opening = $open->{slash} == 0 || $before =~ /[\s:=,(\[{'`]/;
      my $closing = $close->{quote} + 1 >= length($text) || $after =~ /[\s,.;:)\]}"'`]/;
      if ( $opening && $closing ) {
        push @intervals, [ $open->{quote} + 1, $close->{slash} ];
        $i += 2;
      }
      else { $i++ }
    }
    @tokens = ();
  };

  for ( my $i = 0; $i < length($text); ) {
    my $c = substr( $text, $i, 1 );
    if (!$outer) {
      $outer = 1 if $c eq '"';
      $i++;
      next;
    }
    if ( $c eq '\\' ) {
      my $end = $i + 1;
      $end++ while $end < length($text) && substr( $text, $end, 1 ) eq '\\';
      if ( substr( $text, $end, 1 ) eq '"' && ( $end - $i ) % 2 == 1 ) {
        push @tokens, { slash => $i, quote => $end } if $end - $i == 1;
        $i = $end + 1;
        next;
      }
      $i = $end;
      next;
    }
    if ( $c eq '"' ) {
      $finish_outer->();
      $outer = 0;
    }
    $i++;
  }
  return @intervals;
}

sub _in_nested_json_string {
  my ( $text, $offset ) = @_;
  for my $interval ( _nested_json_intervals($text) ) {
    return 1 if $offset >= $interval->[0] && $offset < $interval->[1];
  }
  return 0;
}

sub _encoded_root {
  my ( $path, $depth ) = @_;
  my $encoded = $path;
  $encoded = _json_string_contents($encoded) for 1 .. $depth;
  return $encoded;
}

sub _expected_root_depth {
  my ( $expected, $offset, $encoding ) = @_;
  return 0 if $encoding eq 'decoded';
  return 0 if $encoding eq 'stream' && !_in_json_string( $expected, $offset );
  return 1 + ( _in_nested_json_string( $expected, $offset ) ? 1 : 0 );
}

sub _replace_exact_where {
  my ( $text, $needle, $replacement, $accept ) = @_;
  my ( $out, $from ) = ( '', 0 );
  while (1) {
    my $at = index( $text, $needle, $from );
    return $out.substr( $text, $from ) if $at == -1;
    $out .= substr( $text, $from, $at - $from ).( $accept->( $text, $at ) ? $replacement : $needle );
    $from = $at + length($needle);
  }
}

sub abstract_roots {
  my ( $text, $r, $encoding ) = @_;
  for my $pair ( placeholders($r) ) {
    my ( $path, $name ) = @$pair;
    my $escaped = _json_string_contents($path);
    if ( $encoding eq 'decoded' ) {
      $text =~ s/\Q$path\E/$name/g;
    }
    elsif ( $encoding eq 'json' ) {
      $text =~ s/\Q$escaped\E/$name/g;
    }
    else {
      $text = _replace_exact_where( $text, $escaped, $name, \&_in_json_string );
      $text = _replace_exact_where( $text, $path, $name, sub { !_in_json_string( $_[0], $_[1] ) } );
    }
  }
  return $text;
}

my @PLACEHOLDER_NAMES = ( '${HOME}', '${PROJECT}', '${TMP}' );

sub _placeholder_at {
  my ( $text, $offset ) = @_;
  for my $name (@PLACEHOLDER_NAMES) { return $name if substr( $text, $offset, length($name) ) eq $name }
  return undef;
}

sub _path_close {
  my ( $text, $offset ) = @_;
  my $before = $offset > 0 ? substr( $text, $offset - 1, 1 ) : '';
  return $before if $before eq '"' || $before eq q{'} || $before eq '`';
  return ')' if $before eq '(';
  return undef;
}

sub _ends_path {
  my ( $c, $close ) = @_;
  return 1 if defined $close && $c eq $close;
  return 1 if $c =~ /["'`)\]},;:\r\n\x{2014}]/;
  return !defined($close) && $c =~ /\s/ ? 1 : 0;
}

sub oracle_path_equal {
  my ( $actual, $expected, $encoding, $roots ) = @_;
  my ( $a, $e, $in_path, $close ) = ( 0, 0, 0, undef );
  while ( $e < length $expected ) {
    my $placeholder = _placeholder_at( $expected, $e );
    if ( defined $placeholder ) {
      my $consumed = length($placeholder);
      if ( substr( $actual, $a, length($placeholder) ) ne $placeholder ) {
        return 0 unless $roots;
        my ($pair) = grep { $_->[1] eq $placeholder } placeholders($roots);
        return 0 unless $pair;
        my $candidate = _encoded_root( $pair->[0], _expected_root_depth( $expected, $e, $encoding ) );
        return 0 unless substr( $actual, $a, length($candidate) ) eq $candidate;
        $consumed = length($candidate);
      }
      $a += $consumed;
      $e += length($placeholder);
      $in_path = substr( $expected, $e, 1 ) eq '/' ? 1 : 0;
      $close = $in_path ? _path_close( $expected, $e - length($placeholder) ) : undef;
      next;
    }
    my $wanted = substr( $expected, $e, 1 );
    $in_path = 0 if $in_path && _ends_path( $wanted, $close );
    if ( $in_path && $wanted eq '/' ) {
      if ( substr( $actual, $a, 1 ) eq '/' ) { $a++ }
      else {
        my $separator = '\\' x ( 2 ** _expected_root_depth( $expected, $e, $encoding ) );
        return 0 unless substr( $actual, $a, length($separator) ) eq $separator;
        $a += length($separator);
      }
      $e++;
      next;
    }
    return 0 if substr( $actual, $a, 1 ) ne $wanted;
    $a++;
    $e++;
  }
  return $a == length($actual) ? 1 : 0;
}

sub actual_text_for_expected {
  my ( $actual, $expected, $encoding, $roots ) = @_;
  return oracle_path_equal( $actual, $expected, $encoding, $roots ) ? $expected : $actual;
}

sub _assign_array_item {
  my ( $actual, $expected, $actual_index, $matched, $seen ) = @_;
  for my $expected_index ( 0 .. $#$expected ) {
    next if $seen->{$expected_index} || !values_equivalent( $actual->[$actual_index], $expected->[$expected_index] );
    $seen->{$expected_index} = 1;
    if ( !exists $matched->{$expected_index}
      || _assign_array_item( $actual, $expected, $matched->{$expected_index}, $matched, $seen ) ) {
      $matched->{$expected_index} = $actual_index;
      return 1;
    }
  }
  return 0;
}

sub values_equivalent {
  my ( $actual, $expected ) = @_;
  my ( $a_type, $e_type ) = ( js_type($actual), js_type($expected) );
  return oracle_path_equal( $actual, $expected, 'decoded' ) if $a_type eq 'string' && $e_type eq 'string';
  if ( $a_type eq 'array' && $e_type eq 'array' ) {
    return 0 unless @$actual == @$expected;
    my %matched;
    for my $i ( 0 .. $#$actual ) { return 0 unless _assign_array_item( $actual, $expected, $i, \%matched, {} ) }
    return 1;
  }
  if ( $a_type eq 'object' && $e_type eq 'object' ) {
    my @a = js_sort_keys( keys %$actual );
    my @e = js_sort_keys( keys %$expected );
    return 0 unless @a == @e;
    for my $i ( 0 .. $#a ) { return 0 if $a[$i] ne $e[$i] || !values_equivalent( $actual->{$a[$i]}, $expected->{$e[$i]} ) }
    return 1;
  }
  return js_stringify($actual) eq js_stringify($expected) ? 1 : 0;
}

sub actual_for_expected {
  my ( $actual, $expected ) = @_;
  return values_equivalent( $actual, $expected ) ? $expected : $actual;
}

sub concrete {
  my ( $text, $r ) = @_;
  $text =~ s/\Q$_->[1]\E/$_->[0]/g for placeholders($r);
  return $text;
}

sub concrete_json_text {
  my ( $text, $r ) = @_;
  for my $pair ( placeholders($r) ) {
    my ( $path, $name ) = @$pair;
    my $escaped = _json_string_contents($path);
    $text =~ s/\Q$name\E/$escaped/g;
  }
  return $text;
}

sub abstract_deep {
  my ( $v, $r ) = @_;
  my $type = js_type($v);
  return abstract_roots( $v, $r, 'decoded' ) if $type eq 'string';
  return [ map { abstract_deep( $_, $r ) } @$v ] if $type eq 'array';
  return js_ordered( map { ( $_ => abstract_deep( $v->{$_}, $r ) ) } keys %$v ) if $type eq 'object';
  return $v;
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
    my $text = read_text("$from/$rel");
    $dest->spew_raw( encode_text( $rel =~ /\.json\z/ ? concrete_json_text( $text, $r ) : concrete( $text, $r ) ) );
  }
}

# Copy a source tree byte for byte, in a new file's mode: the checkout's mode of the fixture
# does not count (README: trees).
sub copy_tree {
  my ( $from, $to ) = @_;
  for my $rel ( walk($from) ) {
    my $dest = path( $to, unescape_name($rel) );
    $dest->parent->mkpath;
    $dest->spew_raw( path( $from, $rel )->slurp_raw );
  }
}

# A native filesystem path as an absolute file URL safe inside git-config's quoted value.
sub file_url {
  my ( $path ) = @_;
  my $p = to_posix("$path");
  $p = "/$p" if $^O eq 'MSWin32' && $p =~ /\A[A-Za-z]:\//;
  my $bytes = encode_text($p);
  $bytes =~ s{([^A-Za-z0-9\-._~/:])}{sprintf '%%%02X', ord($1)}ge;
  return "file://$bytes";
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
      my $staged = git_ok( "$repo", 'ls-files', '--stage', '-z' );
      my @regular = map { s/[^\t]*\t//r } grep { /\A100/ } split /\0/, $staged;
      git_ok( "$repo", 'update-index', '--chmod=-x', '--', @regular ) if @regular;
      git_ok( "$repo", 'update-index', '--chmod=+x', '--', @{ $commit->{executable} } ) if @{ $commit->{executable} // [] };
      git_ok( "$repo", 'commit', '-q', '--allow-empty', '-m', "conformance $i" );
      git_ok( "$repo", 'tag', $commit->{tag} )       if defined $commit->{tag};
      git_ok( "$repo", 'branch', $commit->{branch} ) if defined $commit->{branch};
    }
    push @config, '[url "'.file_url($repo).'"]', "\tinsteadOf = ".$g->{url};
  }
  path( $r->{tmp}, 'gitconfig' )->spew_raw( encode_text( join( "\n", @config )."\n" ) );
}

# A `cli` step's environment, built from nothing (README: cli): the case's, then the step's
# variables on top of the fixed ones; a step's null unsets one. Values are bytes.
sub cli_env {
  my ( $c, $step, $r ) = @_;
  my %env = (
    PATH                => $ENV{PATH} // '',
    HOME                => $r->{home},
    CODEX_HOME          => "$r->{home}/.codex",
    GIT_CONFIG_GLOBAL   => "$r->{tmp}/gitconfig",
    GIT_CONFIG_NOSYSTEM => '1',
    LC_ALL              => 'C',
  );
  if ( $^O eq 'MSWin32' ) {
    @env{qw( USERPROFILE LOCALAPPDATA TEMP TMP )} = ( $r->{home}, "$r->{home}/AppData/Local", $r->{tmp}, $r->{tmp} );
  }
  $env{PERL5LIB} = $ENV{PERL5LIB} if defined $ENV{PERL5LIB};    # a Perl CLI's modules
  $env{$_} = encode_text( concrete( $c->{env}{$_}, $r ) ) for keys %{ $c->{env} // {} };
  for my $k ( keys %{ $step->{env} // {} } ) {
    my $v = $step->{env}{$k};
    if   ( defined $v ) { $env{$k} = encode_text( concrete( $v, $r ) ) }
    else                { delete $env{$k} }
  }
  return \%env;
}

# Input placeholders in every string of a JSON value, key order kept.
sub concrete_deep {
  my ( $v, $r ) = @_;
  my $type = js_type($v);
  return concrete( $v, $r ) if $type eq 'string';
  return [ map { concrete_deep( $_, $r ) } @$v ] if $type eq 'array';
  return js_ordered( map { ( $_ => concrete_deep( $v->{$_}, $r ) ) } keys %$v ) if $type eq 'object';
  return $v;
}

# Run a `cli` step's CLI (README: cli): stdin a pipe with the step's bytes. Returns
# { exit, stdout, stderr } (bytes), or { failed => why } for a CLI that does not start, outlives
# its timeout or dies of a signal.
sub run_cli {
  my ( $prefix, $step, $r, $env, $timeout_ms ) = @_;
  my $argv = $step->{argv};
  return { failed => 'argv is no array of strings' }
    unless js_type($argv) eq 'array' && !grep { js_type($_) ne 'string' } @$argv;
  my $stdin =
      !exists $step->{stdin}                  ? ''
    : js_type( $step->{stdin} ) eq 'string' ? concrete( $step->{stdin}, $r )
    :                                         js_stringify( concrete_deep( $step->{stdin}, $r ) );
  my $res = run_command(
    cmd        => [ @$prefix, map { encode_text( concrete( $_, $r ) ) } @$argv ],
    cwd        => encode_text( defined $step->{cwd} ? concrete( $step->{cwd}, $r ) : $r->{project} // $r->{cwd} ),
    env        => $env,
    stdin      => encode_text($stdin),
    timeout_ms => $timeout_ms // $CLI_TIMEOUT_MS,
  );
  my $what = join ' ', @$prefix;
  return { failed => "$what did not start: $res->{spawn_error}{message}" } if $res->{spawn_error};
  return { failed => "$what outlived its timeout" }                         if $res->{timed_out};
  return { failed => "$what was killed by signal $res->{signal}" }         if !defined $res->{code};
  return { exit => $res->{code}, stdout => $res->{stdout}, stderr => $res->{stderr} };
}

# Replace exact roots on raw stream bytes; expected-aware comparison handles separators.
sub abstract_bytes {
  my ( $bytes, $r, $version ) = @_;
  for my $pair ( placeholders($r) ) {
    my ( $path, $name ) = @$pair;
    my $raw     = encode_text($path);
    my $escaped = encode_text( _json_string_contents($path) );
    $bytes = _replace_exact_where( $bytes, $escaped, $name, \&_in_json_string );
    $bytes = _replace_exact_where( $bytes, $raw, $name, sub { !_in_json_string( $_[0], $_[1] ) } );
  }
  if ($version) { $bytes =~ s/\Q$_\E/\${VERSION}/g for @VERSIONS }
  return $bytes;
}

# An expected stream: no file means empty.
sub read_stream { -f $_[0] ? path( $_[0] )->slurp_raw : '' }

# The relative paths under HOME a tree leaves out (README: trees): the marker, skilletor's state
# dir and the CLI's own, ${CLAUDE_CONFIG_DIR:-${HOME}/.claude}/skilletor.
sub home_skip {
  my ( $r, $config_dir ) = @_;
  my $state = ( defined $config_dir && length $config_dir ? $config_dir : "$r->{home}/.claude" ).'/skilletor';
  return [ '.claude/skilletor', '.claude.json', index( $state, "$r->{home}/" ) == 0 ? substr( $state, length( $r->{home} ) + 1 ) : () ];
}

# The files a tree step compares (README: trees): HOME but the state dirs and the marker, all of
# PROJECT – each without the .git a gitInit made there – and all of ${TMP}/cwd.
sub snapshot {
  my ( $r, $skip, $git_init ) = @_;
  my %init = map { ( $_ => 1 ) } @$git_init;
  my %out;
  my $file_text = sub {
    my ( $root, $rel ) = @_;
    return abstract_roots( read_text("$root/$rel"), $r, $rel =~ /\.json\z/ ? 'json' : 'decoded' );
  };
  $out{ "home/".escape_name($_) } = $file_text->( $r->{home}, $_ ) for walk( $r->{home}, [ @$skip, $init{home} ? '.git' : () ] );
  if ( $r->{project} ) {
    $out{ "project/".escape_name($_) } = $file_text->( $r->{project}, $_ ) for walk( $r->{project}, [ $init{project} ? '.git' : () ] );
  }
  $out{ "cwd/".escape_name($_) } = $file_text->( $r->{cwd}, $_ ) for walk( $r->{cwd} );
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
  my $r = { tmp => $tmp, home => "$tmp/home", cwd => "$tmp/cwd" };
  $r->{project} = "$tmp/project" if -d "$case_dir/project";

  local $ENV{GIT_CONFIG_GLOBAL}   = "$tmp/gitconfig";
  local $ENV{GIT_CONFIG_NOSYSTEM} = '1';
  local @ENV{qw( CODEX_HOME HERMES_HOME CLAUDE_PLUGIN_ROOT CLAUDE_CONFIG_DIR )};
  delete @ENV{qw( CODEX_HOME HERMES_HOME CLAUDE_PLUGIN_ROOT CLAUDE_CONFIG_DIR )};
  $ENV{$_} = encode_text( concrete( $c->{env}{$_}, $r ) ) for sort keys %{ $c->{env} // {} };
  build_git( $case_dir, $c, $r );
  path( $r->{home}, '.claude' )->mkpath;
  my $marker = !( exists $c->{claude} && !$c->{claude} );    # "claude": false – no marker, Claude Code is not in use
  path( $r->{home}, '.claude.json' )->spew_raw("{}\n") if $marker;    # Claude Code is in use (spec §14.1)
  if ( defined $ENV{CLAUDE_CONFIG_DIR} ) {    # Claude Code keeps its .claude.json inside a custom config dir
    path( $ENV{CLAUDE_CONFIG_DIR} )->mkpath;
    path( $ENV{CLAUDE_CONFIG_DIR}, '.claude.json' )->spew_raw("{}\n") if $marker;
  }
  copy_input( "$case_dir/home", $r->{home}, $r );
  if ( $r->{project} ) {
    path( $r->{project} )->mkpath;
    copy_input( "$case_dir/project", $r->{project}, $r );
  }
  path( $r->{cwd} )->mkpath;
  my $git_init = $c->{gitInit} // [];
  for my $where (@$git_init) {
    my $dir = $where eq 'home' ? $r->{home} : $where eq 'project' ? $r->{project} : undef;
    return fail("gitInit names $where, which this case does not have") unless defined $dir;
    git_ok( $dir, 'init', '-q', '-b', 'main' );
  }
  my $sk = Skilletor::Engine->new(
    home             => $r->{home},
    ( $r->{project} ? ( project_dir => $r->{project} ) : () ),
    state_root       => "$r->{home}/.claude/skilletor",
    codex_home       => "$r->{home}/.codex",
    hermes_home      => "$r->{home}/.hermes",
    require_harness  => 1,              # the reference's resolve: a machine without a harness is an error
    # Neither dir lies in a work tree, git tracks none of their files – unless gitInit made one:
    # then git answers, as for the CLI.
    ( @$git_init ? () : ( is_git_work_tree => sub { 0 }, git_tracked => sub { [] } ) ),
    host             => { name => 'conformance', os => 'linux' },    # for templates (README: environment)
    user             => { name => 'conformance', home => $r->{home} },
  );

  for my $step ( @{ $c->{steps} } ) {
    my $id = $step->{id};
    my $variant = ( $engine->{steps} // {} )->{$id} // {};
    if ( defined $variant->{skip} ) {
      pass( "step $id skipped: $variant->{skip}" );
      next;
    }
    my $expected = defined $variant->{expected} ? "$case_dir/$variant->{expected}" : "$case_dir/expected/$id";
    my $config_dir = $ENV{CLAUDE_CONFIG_DIR};
    if ( $step->{op} eq 'cli' ) {
      my $env = cli_env( $c, $step, $r );
      $config_dir = $env->{CLAUDE_CONFIG_DIR};
      my $got = run_cli( \@CLI, $step, $r, $env );
      if ( defined $got->{failed} ) {
        fail("step $id: $got->{failed}");
        next;
      }
      my $want = js_parse( read_text("$expected.json") );
      ok( $want->{exit} == 0, "step $id: a hook step expects exit 0" ) if ( $step->{argv}[0] // '' ) eq 'hook';
      is( js_stringify( canonical( { exit => $got->{exit} } ), 2 ), js_stringify( canonical($want), 2 ), "step $id: the exit code" )
        or diag( "stderr: $got->{stderr}" );
      for my $stream (qw( stdout stderr )) {
        my $actual = abstract_bytes( $got->{$stream}, $r, $step->{version} );
        my $want_stream = read_stream("$expected.$stream");
        is( actual_text_for_expected( $actual, $want_stream, 'stream', $r ), $want_stream, "step $id: $stream" );
      }
    }
    else {
      my %opts = ( scope => $step->{scope} // 'all' );
      my $result =
          $step->{op} eq 'resolve' ? resolve_view( $sk->resolve(%opts) )
        : $step->{op} eq 'sync'    ? $sk->sync( %opts, force => $step->{force} ? 1 : 0 )
        : $step->{op} eq 'check'   ? $sk->check(%opts)
        : $step->{op} eq 'status'  ? $sk->status(%opts)
        :                            die "unknown op $step->{op}";
      my $actual = canonical( abstract_deep( $result, $r ) );
      my $want   = canonical( js_parse( read_text("$expected.json") ) );
      is( js_stringify( actual_for_expected( $actual, $want ), 2 ), js_stringify( $want, 2 ), "step $id" );
    }
    next unless $step->{tree};
    my $have  = snapshot( $r, home_skip( $r, $config_dir ), $git_init );
    my %want  = map { ( $_ => read_text("$expected/$_") ) } walk($expected);
    is_deeply( [ sort keys %$have ], [ sort keys %want ], "step $id: the files in the tree" );
    for my $rel ( sort keys %want ) {
      my $encoding = $rel =~ /\.json\z/ ? 'json' : 'decoded';
      is( actual_text_for_expected( $have->{$rel}, $want{$rel}, $encoding, $r ), $want{$rel}, "step $id: $rel" );
    }
    my @execs = grep {
      my ( $where, $rel ) = unescape_name($_) =~ m{\A(home|project|cwd)/(.*)\z}s;
      ( ( stat( $r->{$where}.'/'.$rel ) )[2] // 0 ) & 0100;
    } sort keys %$have;
    my $want_execs = -f "$expected.executables.json" ? js_parse( read_text("$expected.executables.json") ) : [];
    SKIP: {
      skip 'Windows filesystems expose no POSIX executable-bit contract', 1
        if $^O eq 'MSWin32' && @$want_execs;
      is_deeply( \@execs, [@$want_execs], "step $id: the files with the executable bit" );
    }
  }
}

my @cases = sort grep { -f "$ROOT/$_/case.json" } map { $_->basename } $ROOT->children;
ok( scalar @cases, 'the cases directory holds cases' );
for my $name (@cases) {
  subtest "conformance: $name" => sub { run_case($name) };
}

subtest 'expected oracles distinguish native paths from literal escapes' => sub {
  my $r = {
    tmp => 'C:\\Temp\\fixture', home => 'C:\\Temp\\fixture\\home',
    project => 'C:\\Temp\\fixture\\project', cwd => 'C:\\Temp\\fixture\\cwd',
  };
  my $input = '{"path":"${HOME}/child","literal":"keep\\\\literal"}';
  is_deeply( js_parse( concrete_json_text( $input, $r ) ),
    { path => "$r->{home}/child", literal => 'keep\\literal' }, 'JSON input' );

  my $structured = abstract_deep( {
    path => "$r->{home}\\child\\deep", nativeComponents => "$r->{home}\\next\\tab\\u1234",
    escaped => "$r->{home}\\dev\\t\\u001b[31m", literal => 'keep\\literal',
  }, $r );
  my $structured_expected = {
    path => '${HOME}/child/deep', nativeComponents => '${HOME}/next/tab/u1234',
    escaped => '${HOME}/dev/t\\u001b[31m', literal => 'keep\\literal',
  };
  is_deeply( actual_for_expected( $structured, $structured_expected ), $structured_expected, 'structured output' );

  my $stream = abstract_bytes( encode_text( js_stringify( {
    path => "$r->{project}\\child\\deep", literal => 'keep\\literal',
  } ) ), $r, 0 );
  my $stream_expected = encode_text( js_stringify( { path => '${PROJECT}/child/deep', literal => 'keep\\literal' } ) );
  is( actual_text_for_expected( $stream, $stream_expected, 'stream' ), $stream_expected, 'stream output' );

  my $rejected_ref = "--upload-pack=touch '$r->{project}\\dash-pwned'";
  my $rejected_message = "skilletor: $r->{project}\\.claude\\skilletor.json: sources.team.ref ".js_stringify($rejected_ref)
    .' must not start with '.js_stringify('-').' (git would read it as an option)';
  my $hook_actual = abstract_bytes( encode_text( js_stringify( js_ordered( systemMessage => $rejected_message ) )."\n" ), $r, 0 );
  my $portable_ref = q{--upload-pack=touch '${PROJECT}/dash-pwned'};
  my $portable_message = '${PROJECT}/.claude/skilletor.json: sources.team.ref '.js_stringify($portable_ref)
    .' must not start with '.js_stringify('-').' (git would read it as an option)';
  $portable_message = 'skilletor: '.$portable_message;
  my $hook_expected = encode_text( js_stringify( js_ordered( systemMessage => $portable_message ) )."\n" );
  is( actual_text_for_expected( $hook_actual, $hook_expected, 'stream', $r ), $hook_expected,
    'ordinary and nested JSON-stringified paths compare without changing the rejected payload' );
  my $nested_root = encode_text( _encoded_root( $r->{project}, 2 ) );
  ok( index( $hook_actual, $nested_root ) >= 0, 'fixture contains exactly two root-encoding layers' );
  for my $depth ( 0, 1, 3 ) {
    my $wrong = $hook_actual;
    my $at = index( $wrong, $nested_root );
    substr( $wrong, $at, length($nested_root) ) = encode_text( _encoded_root( $r->{project}, $depth ) );
    ok( !oracle_path_equal( $wrong, $hook_expected, 'stream', $r ), "nested root at wrong encoding depth $depth fails" );
  }
  ( my $changed_payload = $hook_actual ) =~ s/--upload-pack=touch/--upload-pack=remove/;
  ok( !oracle_path_equal( $changed_payload, $hook_expected, 'stream', $r ), 'changed rejected payload fails' );
  ( my $changed_quote = $hook_actual ) =~ s/\\"--upload-pack/"--upload-pack/;
  ok( !oracle_path_equal( $changed_quote, $hook_expected, 'stream', $r ), 'changed nested quoting fails' );
  ( my $missing_open_actual = $hook_actual ) =~ s/\\"--upload-pack/--upload-pack/;
  ( my $missing_open_expected = $hook_expected ) =~ s/\\"--upload-pack/--upload-pack/;
  ( my $missing_close_actual = $hook_actual ) =~ s/dash-pwned'\\"/dash-pwned'/;
  ( my $missing_close_expected = $hook_expected ) =~ s/dash-pwned'\\"/dash-pwned'/;
  isnt( $missing_open_expected, $hook_expected, 'opening-quote fixture changed' );
  isnt( $missing_close_expected, $hook_expected, 'closing-quote fixture changed' );
  ok( !oracle_path_equal( $missing_open_actual, $missing_open_expected, 'stream', $r ),
    'unmatched expected closing quote gives no nested provenance' );
  ok( !oracle_path_equal( $missing_close_actual, $missing_close_expected, 'stream', $r ),
    q{later quoted '-' cannot close an unmatched expected opener} );

  my $raw_json = '{"message":"${HOME}/child\\nnext","tab":"${HOME}/child\\tnext","unicode":"${HOME}/child\\u1234",'
    .'"path":"${HOME}\\\\nested\\\\u-part","literal":"keep\\\\literal"}';
  my $normalized_json = '{"message":"${HOME}/child\\nnext","tab":"${HOME}/child\\tnext","unicode":"${HOME}/child\\u1234",'
    .'"path":"${HOME}/nested/u-part","literal":"keep\\\\literal"}';
  is( actual_text_for_expected( abstract_roots( $raw_json, $r, 'json' ), $normalized_json, 'json' ), $normalized_json,
    'raw JSON file escapes and formatting stay exact' );
  is( actual_text_for_expected( abstract_bytes( $raw_json, $r, 0 ), $normalized_json, 'stream' ), $normalized_json,
    'raw JSON stream escapes and formatting stay exact' );
  my $malformed_root = '{"path":"'.$r->{home}.'\\child"}';
  is( abstract_roots( $malformed_root, $r, 'json' ), $malformed_root,
    'raw JSON root substitution does not repair unescaped Windows bytes' );

  ok( oracle_path_equal( '${HOME}/child\\next', '${HOME}/child\\next', 'decoded' ), 'ambiguous display data stays literal' );
  ok( oracle_path_equal( '${HOME}/child\\next', '${HOME}/child/next', 'decoded' ), 'oracle-designated decoded path separator' );
  ok( !oracle_path_equal( '"${HOME}/child\\next"', '"${HOME}/child/next"', 'json' ), 'single raw-JSON escape is no separator' );
  ok( oracle_path_equal( '"${HOME}/child\\\\next"', '"${HOME}/child/next"', 'json' ), 'encoded raw-JSON separator' );
  ok( oracle_path_equal( '"${HOME}/dir with space\\\\file"', '"${HOME}/dir with space/file"', 'json' ), 'spaces inside a delimited path' );

  my @negative = (
    [ 'changed non-separator', '${HOME}\\child\\wrong', '${HOME}/child/right', 'decoded' ],
    [ 'extra escape', '"${HOME}\\\\child\\\\\\next"', '"${HOME}/child/next"', 'json' ],
    [ 'missing escape', '"${HOME}\\\\childnext"', '"${HOME}/child/next"', 'json' ],
    [ 'formatting', '{ "path":"${HOME}\\\\child"}', '{"path":"${HOME}/child"}', 'stream' ],
    [ 'unrelated after path', '${HOME}\\child; data \\value', '${HOME}/child; data /value', 'decoded' ],
  );
  ok( !oracle_path_equal( @$_[ 1 .. 3 ] ), $_->[0] ) for @negative;

  my $duplicates = [ { path => '${HOME}\\a' }, { path => '${HOME}\\a' } ];
  ok( values_equivalent( $duplicates, [ { path => '${HOME}/a' }, { path => '${HOME}/a' } ] ), 'duplicates match' );
  ok( !values_equivalent( $duplicates, [ { path => '${HOME}/a' } ] ), 'missing duplicate fails' );
  ok( values_equivalent( [ { path => '${HOME}\\b' }, { path => '${HOME}\\a' } ],
    [ { path => '${HOME}/a' }, { path => '${HOME}/b' } ] ), 'array order remains insignificant' );
};

subtest 'git fixture executable mode is declared independently for every commit' => sub {
  my $tmp = tempdir;
  my $case_dir = $tmp->child('case');
  for my $tree (qw( one two )) {
    my $dir = $case_dir->child($tree);
    $dir->mkpath;
    $dir->child('run.sh')->spew_raw("#!/bin/sh\nexit 0\n");
  }
  my $fixture = { git => { shared => {
    url => 'https://conformance.invalid/shared.git',
    commits => [ { tree => 'one', executable => ['run.sh'] }, { tree => 'two' } ],
  } } };
  my @histories;
  for my $name (qw( a b )) {
    my $root = $tmp->child("run-$name");
    $root->mkpath;
    my $r = { tmp => "$root", home => "$root/home", cwd => "$root/cwd" };
    local @ENV{qw( GIT_CONFIG_COUNT GIT_CONFIG_KEY_0 GIT_CONFIG_VALUE_0 GIT_CONFIG_NOSYSTEM GIT_CONFIG_GLOBAL )} =
      ( '1', 'core.filemode', 'false', '1', "$root/global.gitconfig" );
    build_git( "$case_dir", $fixture, $r );
    my $repo = "$root/git/shared";
    my @commits = split /\n/, git_out( $repo, 'rev-list', '--reverse', 'HEAD' );
    my @modes = map { substr( git_out( $repo, 'ls-tree', $_, '--', 'run.sh' ), 0, 6 ) } @commits;
    is_deeply( \@modes, [qw( 100755 100644 )], "$name: executable then regular" );
    my @trees = map { git_out( $repo, 'show', '-s', '--format=%T', $_ ) } @commits;
    isnt( $trees[0], $trees[1], "$name: mode-only change has a different exact Git tree" );
    push @histories, \@commits;
  }
  is_deeply( $histories[0], $histories[1], 'fixed metadata produces exact commit identities' );
};

# The harness itself (README: cli), on a stand-in CLI that reports what it got. Asserts: the
# child's environment is exactly the fixed variables, the case's and the step's (a variable of the
# runner – CLAUDE_PROJECT_DIR here – never leaks in, null unsets); argv, cwd and stdin take the
# input placeholders; stdin is a string's bytes or a value's JSON, through a pipe.
subtest "a cli step's CLI gets the README's environment, argv, cwd and stdin – nothing else" => sub {
  my $tempdir = tempdir( 'skilletor-conformance-XXXXXX', TMPDIR => 1 );
  my $tmp = Cwd::realpath("$tempdir");
  my $r = { tmp => $tmp, home => "$tmp/home", cwd => "$tmp/cwd" };
  path($_)->mkpath for $r->{home}, $r->{cwd};
  my @echo = ( $^X, '-MCwd', '-e', 'local $/; my $in = <STDIN>; print join "\0", Cwd::getcwd(), -p STDIN ? "pipe" : "no pipe", $in, @ARGV, map { "$_=$ENV{$_}" } sort keys %ENV' );
  my $c = { env => { CLAUDE_CONFIG_DIR => '${HOME}/cfg', DROPPED => 'x' } };
  my $step = { id => 'echo', op => 'cli', argv => [ 'status', '${HOME}' ], env => { DROPPED => undef, EXTRA => '${TMP}/e' }, stdin => js_ordered( cwd => '${HOME}', n => [1] ) };
  my @forbidden = qw( CLAUDE_PROJECT_DIR SKILLETOR_BIN GITHUB_TOKEN );
  local @ENV{@forbidden} = map { "conformance-forbidden-$_" } @forbidden;
  my $got = run_cli( \@echo, $step, $r, cli_env( $c, $step, $r ) );
  my @got = split /\0/, $got->{stdout}, -1;
  is_deeply(
    [ @got[ 0 .. 4 ] ],
    [ $r->{cwd}, 'pipe', js_stringify( concrete_deep( $step->{stdin}, $r ) ), 'status', $r->{home} ],
    'cwd, stdin as JSON through a pipe, argv'
  );
  my %got_env = map { split /=/, $_, 2 } @got[ 5 .. $#got ];
  my %env = (
    PATH => $ENV{PATH} // '', HOME => $r->{home}, CODEX_HOME => "$r->{home}/.codex", GIT_CONFIG_GLOBAL => "$tmp/gitconfig",
    GIT_CONFIG_NOSYSTEM => '1', LC_ALL => 'C', CLAUDE_CONFIG_DIR => concrete( '${HOME}/cfg', $r ), EXTRA => concrete( '${TMP}/e', $r ),
    ( defined $ENV{PERL5LIB} ? ( PERL5LIB => $ENV{PERL5LIB} ) : () ),
  );
  @env{qw( USERPROFILE LOCALAPPDATA TEMP TMP )} = ( $r->{home}, "$r->{home}/AppData/Local", $r->{tmp}, $r->{tmp} )
    if $^O eq 'MSWin32';
  my @allowed = $^O eq 'darwin' ? ('__CF_USER_TEXT_ENCODING')
    : $^O eq 'MSWin32' ? qw( LOGONSERVER SYSTEMDRIVE SYSTEMROOT USERDOMAIN USERNAME WINDIR ) : ();
  my %allowed = map { $_ => 1 } @allowed;
  my @unexpected = grep { !exists $env{$_} && !$allowed{$_} } keys %got_env;
  is_deeply( [ sort @unexpected ], [], 'no unknown child environment keys' );
  delete @got_env{ keys %allowed };
  is_deeply( \%got_env, \%env, 'the isolated environment plus known runtime additions only' );
  ok( !exists $got_env{$_}, "$_ does not leak" ) for @forbidden;
  my $raw = { %$step, stdin => 'not json ${TMP}', cwd => '${HOME}' };
  my @raw_got = split /\0/, run_cli( \@echo, $raw, $r, cli_env( $c, $raw, $r ) )->{stdout}, -1;
  is_deeply( [ @raw_got[ 0 .. 2 ] ], [ $r->{home}, 'pipe', "not json $tmp" ], 'a string is stdin as it is; a step cwd' );

  # Capture stdin unchanged: omitted stdin is empty, but a present JSON null is the four bytes
  # `null`. Exercise the conformance runner and ParityCLI, which t/65 uses for interleaved steps.
  my @capture = ( $^X, '-e', 'binmode STDIN; binmode STDOUT; local $/; my $in = <STDIN>; print STDOUT $in // q{}' );
  my @stdin_cases = (
    [ 'absent',                 {},                                                     '' ],
    [ 'JSON null',              { stdin => undef },                                     'null' ],
    [ 'empty string',           { stdin => '' },                                        '' ],
    [ 'the string null',        { stdin => 'null' },                                    'null' ],
    [ 'a scalar',               { stdin => 42 },                                        '42' ],
    [ 'an array',               { stdin => [ 1, 'two' ] },                              '[1,"two"]' ],
    [ 'an object',              { stdin => js_ordered( cwd => '${HOME}', n => [1] ) }, '{"cwd":"'.$r->{home}.'","n":[1]}' ],
    [ 'placeholder text',       { stdin => 'not JSON ${TMP}' },                         "not JSON $tmp" ],
  );
  my $m = { %$r, env => {} };
  my @drivers = (
    [ conformance => sub { run_cli( \@capture, $_[0], $r, cli_env( {}, $_[0], $r ) ) } ],
    [ parity      => sub { SkilletorTest::ParityCLI::run_cli( \@capture, $m, $_[0] ) } ],
  );
  for my $driver (@drivers) {
    for my $case (@stdin_cases) {
      my ( $name, $input, $want ) = @$case;
      my $transport = { id => "capture $name", op => 'cli', argv => [], %$input };
      my $received = $driver->[1]->($transport);
      is( $received->{exit}, 0, "$driver->[0]: $name exits cleanly" );
      is( $received->{stdout}, $want, "$driver->[0]: $name is the exact stdin bytes" );
      is( $received->{stderr}, '', "$driver->[0]: $name writes no stderr" );
    }
  }
};

subtest 'a cli step fails when its CLI dies of a signal or outlives its timeout' => sub {
  my $dir = File::Spec->tmpdir;
  my $r = { tmp => $dir, home => $dir, cwd => $dir };
  my $step = { id => 'dies', op => 'cli', argv => [] };
  my %env = ( PATH => $ENV{PATH} // '' );
  SKIP: {
    skip 'Windows reports process termination as an exit status, not a POSIX child signal', 1 if $^O eq 'MSWin32';
    like( run_cli( [ $^X, '-e', 'kill KILL => $$' ], $step, $r, \%env )->{failed}, qr/killed by signal 9/, 'a signal' );
  }
  like( run_cli( [ $^X, '-e', 'sleep 10' ], $step, $r, \%env, 300 )->{failed}, qr/outlived its timeout/, 'the timeout' );
};

done_testing;
