#!/usr/bin/env perl
# Skilletor::CLI's pieces no conformance case reaches (conformance/ runs the commands
# themselves, against the reference's bytes): the project root of a cwd, a sync's text with
# run-level notes, alone or beside warnings (cases 110-112, 115 and 117 reach a Hermes note
# alone, case 100 the untrusted Codex hook's warning alone; no case has both), the
# lines of a sync that failed after a command's config edit with --json asked for (no command
# takes both), what the argument layer loads, and an edit's config path without any project dir
# (the CLI always has one). The expected text is the reference's (cli.ts syncText, syncFailed;
# report.ts reportText; commands.ts projectRoot).
use strict;
use warnings;
use utf8;
use Test::More;
use FindBin;
use lib "$FindBin::Bin/lib";
use SkilletorTest qw( git_ok );

use Cwd ();
use Encode ();
use Path::Tiny qw( path tempdir );
use Skilletor::CLI qw( project_root_of );
use Skilletor::FSUtil qw( decode_utf8_lossy );
use Skilletor::JSON qw( js_ordered js_parse js_stringify );
use Skilletor::Process qw( run_command );
use Skilletor::Report qw( empty_scope_report );

subtest 'project_root_of: the git top level of a directory, else the directory itself' => sub {
  my $tmp  = tempdir;
  my $root = Cwd::realpath("$tmp");
  local $ENV{GIT_CEILING_DIRECTORIES} = $root;    # whatever holds the temp dir is no work tree here
  my ( $repo, $other ) = ( "$root/repo", "$root/other" );
  path($_)->mkpath for "$repo/sub/deep", $other, "$root/plain";
  git_ok( $_, 'init', '-q', '-b', 'main' ) for $repo, $other;
  is( project_root_of("$repo/sub/deep"), $repo, 'a subdirectory of a work tree: its top level' );
  is( project_root_of($repo),            $repo, 'the top level: itself' );
  is( project_root_of("$root/plain"), "$root/plain", 'outside git: the directory' );
  is( project_root_of("$root/gone"),  "$root/gone",  'a directory git cannot enter: the directory' );
  local $ENV{GIT_DIR} = "$other/.git";
  is( project_root_of("$repo/sub"), $repo, "an exported GIT_DIR does not answer for it: git runs in git's environment" );
};

my $added = js_ordered( %{ empty_scope_report('user') } );
$added->{added} = [ js_ordered( key => 'skills/a', type => 'skill', name => 'a', source => 's' ) ];

subtest "a sync's text: its report, or up to date; run-level lines come in addition" => sub {
  my $text = \&Skilletor::CLI::_sync_text;
  is( $text->( js_ordered( scopes => [ empty_scope_report('user') ] ) ), 'skilletor: up to date', 'nothing to say' );
  is( $text->( js_ordered( scopes => [$added] ) ), "skilletor: user scope\n  + skills/a (active now)", 'a change' );
  is(
    $text->( js_ordered( scopes => [ empty_scope_report('user') ], warnings => ['the hook is not trusted'] ) ),
    "skilletor: up to date\nskilletor: warning: the hook is not trusted",
    'only a run-level warning: up to date, then the warning'
  );
  is(
    $text->( js_ordered( scopes => [], notes => ['hermes gets no agents'] ) ),
    "skilletor: up to date\nskilletor: note: hermes gets no agents",
    'only a note: the same'
  );
  is(
    $text->( js_ordered( scopes => [$added], warnings => ['w'], notes => ['n'] ) ),
    "skilletor: user scope\n  + skills/a (active now)\nskilletor: warning: w\nskilletor: note: n",
    'a change and run-level lines: no up to date'
  );
  is( $text->( js_ordered( scopes => [ empty_scope_report('user') ], warnings => [], notes => [] ) ),
    'skilletor: up to date', 'empty run-level lists say nothing' );
};

sub stderr_of {
  my ( $code ) = @_;
  my $buf = '';
  my $ret;
  {
    local *STDERR;
    open( STDERR, '>', \$buf ) or die "stderr to a buffer: $!";
    $ret = $code->();
  }
  return ( $ret, Encode::decode( 'UTF-8', $buf ) );
}

subtest 'a sync that stopped at a config error: exit 2, its report on stderr' => sub {
  my $r = js_ordered( scopes => [], error => "bad \x{1b}[31mconfig" );
  my $failed = \&Skilletor::CLI::_sync_failed;
  is_deeply( [ stderr_of( sub { $failed->($r) } ) ], [ 2, "skilletor: config error, nothing changed — bad \\u001b[31mconfig\n" ],
    'the text, escaped' );
  is_deeply(
    [ stderr_of( sub { $failed->( $r, json => 1 ) } ) ],
    [ 2, qq({\n  "scopes": [],\n  "error": "bad \\u001b[31mconfig"\n}\n) ],
    '--json: the report as JSON'
  );
  is_deeply(
    [ stderr_of( sub { $failed->( $r, json => 1, saved => '/p/.claude/skilletor.json' ) } ) ],
    [
      2,
      "skilletor: config error, nothing synced — bad \\u001b[31mconfig\n"
        ."skilletor: the config edit itself was saved in /p/.claude/skilletor.json (not rolled back); fix the error, then run skilletor sync\n"
    ],
    "after a command's config edit: two lines naming the file that stays, never JSON (k103)"
  );
};

# --help, --version and a usage error answer before any engine is built (spec §7: they stay
# quick). Asserted in a fresh perl, whose %INC then holds what the run loaded: never the engine,
# the commands or the config loader – for the config commands' operands and options too. A
# command that runs loads the commands.
subtest 'the argument layer loads neither the engine nor the commands' => sub {
  my $home = tempdir;
  my $script = <<'END';
use Skilletor::CLI;
my $code;
{
  local ( *STDOUT, *STDERR );
  open( STDOUT, '>', \my $out ) or die;
  open( STDERR, '>', \my $err ) or die;
  $code = Skilletor::CLI::run(@ARGV);
}
print $code, ' ', join( ',', grep { m{\ASkilletor/(?:Engine|Commands|Config)\.pm\z} } sort keys %INC ), "\n";
END
  my $run = sub {
    my $r = run_command( cmd => [ $^X, ( map { "-I$_" } grep { !ref } @INC ), '-e', $script, '--', @_ ], env => { %ENV, HOME => "$home" } );
    return $r->{stdout} =~ s/\n\z//r;
  };
  my @quick = ( ['--help'], ['--version'], ['trust'], [ 'trust', '' ], [ 'trust', 'x', '--json' ], ['source'], [ 'source', 'remove' ],
    [ 'source', 'list', '--force' ], [ 'source', 'remove', 'x', '--json' ], [ 'trust', 'x', '--help' ], ['add'], [ 'add', '--project' ],
    [ 'add', 'x', './y', '--json' ], [ 'add', './y', '--scope', 'user' ], [ 'add', 'x', './y', '-h' ], [ 'available', '--project' ],
    [ 'available', 'x', '--scope', 'user' ], [ 'available', 'x', '--force' ], [ 'available', '--json', '--help' ], ['install'],
    [ 'install', '--project' ], [ 'install', 'x@y', '--json' ], [ 'install', 'x@y', '--scope', 'user' ], [ 'install', 'x@y', '--force' ],
    [ 'install', 'x@y', '-h' ], ['uninstall'], [ 'uninstall', '--project' ], [ 'uninstall', 'x@y', '--json' ],
    [ 'uninstall', 'x@y', '--scope', 'user' ], [ 'uninstall', 'x@y', '--force' ], [ 'uninstall', 'x@y', '-h' ] );
  for my $argv (@quick) {
    like( $run->(@$argv), qr/\A[02] \z/, "@$argv: answered, nothing of the engine loaded" );
  }
  like( $run->( 'source', 'list', '--project-dir', "$home" ), qr{\A0 .*Skilletor/Commands\.pm}, 'source list: the commands loaded' );
  like( $run->( 'add', 'bad name', './y', '--project-dir', "$home" ), qr{\A1 .*Skilletor/Commands\.pm}, 'add: the commands loaded' );
  like( $run->( 'available', '--json', '--project-dir', "$home" ), qr{\A0 .*Skilletor/Commands\.pm}, 'available: the commands loaded' );
  like( $run->( 'install', 'bad', '--project-dir', "$home" ), qr{\A1 .*Skilletor/Commands\.pm}, 'install: the commands loaded' );
  like( $run->( 'uninstall', 'bad', '--project-dir', "$home" ), qr{\A1 .*Skilletor/Commands\.pm}, 'uninstall: the commands loaded' );
};

# What --version, --help and a usage error cost is what they load (k199): the CLI module, the
# pragmas and Exporter it uses, nothing else – no module of the dist, no Encode, no Moo. Asserted
# in a fresh perl against what that perl had loaded before the CLI, so a switch of its own
# (PERL5OPT) counts for nothing; the CLI writes to the real stdout, the last line is the count.
subtest '--version, --help and a usage error load the CLI module alone' => sub {
  my $home = tempdir;
  my $script = <<'END';
my %before = map { ( $_ => 1 ) } keys %INC;
require Skilletor::CLI;
my $code = Skilletor::CLI::run(@ARGV);
print "\n", $code, ' ', join( ',', sort grep { !$before{$_} } keys %INC ), "\n";
END
  my $loaded = 'Exporter.pm,Skilletor/CLI.pm,constant.pm,strict.pm,utf8.pm,warnings.pm,warnings/register.pm';
  my $run = sub {
    my $r = run_command( cmd => [ $^X, ( map { "-I$_" } grep { !ref } @INC ), '-e', $script, '--', @_ ], env => { %ENV, HOME => "$home" } );
    return ( $r->{stdout} =~ /([^\r\n]*)\r?\n\z/ )[0];
  };
  for my $argv ( ['--version'], ['-v'], [ '--version', 'sync' ], ['--help'], ['-h'], [], [ 'sync', '--help' ], [ 'hook', '-h' ] ) {
    is( $run->(@$argv), "0 $loaded", ( "@$argv" || 'no arguments' ).': nothing loaded beyond the CLI module' );
  }
  for my $argv ( ['nope'], ['--nope'], [ 'sync', '--bogus' ], [ 'status', '--scope', 'nope' ], [ 'sync', '--scope' ], ['add'],
    ['trust'], ['source'], [ 'source', 'remove' ], ['install'], [ 'uninstall', '--project' ], [ 'check', '--force' ] ) {
    is( $run->(@$argv), "2 $loaded", "@$argv: a usage error, nothing loaded beyond the CLI module" );
  }
  like( $run->( Encode::encode( 'UTF-8', 'nöpe' ) ), qr{\A2 .*Encode\.pm.*Skilletor/Report\.pm}, 'a usage error naming non-ASCII: Encode and the report module' );
};

# The CLI's display_safe returns a line of printable ASCII and tabs as it is without loading
# Skilletor::Report (k199): that holds while the report's own display_safe changes none of those
# characters – the test of that – and every other line goes to the report's.
subtest "display_safe: the CLI's shortcut is the report's own" => sub {
  my $ascii = join '', "\t", map { chr } 0x20 .. 0x7E;
  is( Skilletor::Report::display_safe($ascii), $ascii, "the report's display_safe changes no printable ASCII, no tab" );
  for my $line ( $ascii, '', "a\nb", "a\rb", "\x7F", "\e[31mred", "\x{202E}gnp.exe", "caf\x{E9}", "\x{2028}", "x\x{FEFF}" ) {
    is( Skilletor::CLI::display_safe($line), Skilletor::Report::display_safe($line),
      'the same line: '.Skilletor::Report::display_safe($line) );
  }
};

subtest "an edit's config path: the user config, the project's, no project scope" => sub {
  require Skilletor::Commands;
  require Skilletor::Engine;
  my $path = \&Skilletor::Commands::config_path;
  my $engine = sub { Skilletor::Engine->new( home => '/h', claude_config_dir => '', @_ ) };
  is( $path->( $engine->( project_dir => '/p' ), 0 ), '/h/.claude/skilletor.json', 'the user config' );
  is( $path->( $engine->( project_dir => '/p/' ), 1 ), '/p/.claude/skilletor.json', 'the project config' );
  is( $path->( Skilletor::Engine->new( home => '/h', claude_config_dir => '/cfg' ), 0 ), '/cfg/skilletor.json', 'CLAUDE_CONFIG_DIR' );
  my $err = eval { $path->( $engine->(), 1 ); 1 } ? undef : $@;
  isa_ok( $err, 'Skilletor::Error::Command', 'no project dir' );
  is( $err->message, 'no project scope: no project directory', 'no project dir: says so' );
  $err = eval { $path->( $engine->( project_dir => '/h' ), 1 ); 1 } ? undef : $@;
  is( $err->message, 'no project scope: the project directory is the home directory (/h); '
      .'run from a project, pass --project-dir, or drop --project to edit the user config', 'the home as project dir' );
};

subtest 'removed cwd: an explicit project syncs a skill; otherwise the error is actionable' => sub {
  plan skip_all => "Windows cannot remove a process's cwd" if $^O eq 'MSWin32';
  my $tmp = tempdir->realpath;
  my $home = path( $tmp, 'home' );
  my $source = path( $tmp, 'source' );
  my $project = path( $tmp, 'project' );
  path( $home, '.claude' )->mkpath;
  path( $source, 'skills', 'foo' )->mkpath;
  $project->mkpath;
  path( $home, '.claude.json' )->spew_raw("{}\n");
  path( $source, 'skills', 'foo', 'SKILL.md' )->spew_raw("FOO\n");
  path( $home, '.claude', 'skilletor.json' )->spew_raw( js_stringify( js_ordered(
    sources => js_ordered( s => js_ordered( local => "$source" ) ),
    install => js_ordered( skills => ['foo@s'] ),
  ) ) );

  my $bin = path( $FindBin::Bin, '..', 'script', 'skilletor' )->realpath;
  my $lib = path( $FindBin::Bin, '..', 'lib' )->realpath;
  my %env = %ENV;
  delete @env{qw( CLAUDE_CONFIG_DIR CLAUDE_PROJECT_DIR SKILLETOR_PROJECT_DIR HERMES_HOME )};
  @env{qw( HOME CODEX_HOME )} = ( "$home", path( $home, '.no-codex' )->stringify );
  my $run_removed = sub {
    my ( $name, @args ) = @_;
    my $gone = path( $tmp, $name );
    $gone->mkpath;
    return run_command(
      cmd => [ 'sh', '-c', 'cd "$1" && rmdir "$1" && shift && exec "$@"', 'sh', "$gone", $^X, "-I$lib", "$bin", @args ],
      env => \%env,
    );
  };

  my $sync = $run_removed->( 'gone-explicit', 'sync', '--scope', 'user', '--project-dir', "$project" );
  is_deeply( [ $sync->{code}, decode_utf8_lossy( $sync->{stderr} ) ], [ 0, '' ], 'an explicit project dir avoids the removed cwd' );
  is( path( $home, '.claude', 'skills', 'foo', 'SKILL.md' )->slurp_raw, "FOO\n", 'the skill installed' );
  my $lock = js_parse( path( $home, '.claude', 'skilletor.lock.json' )->slurp_raw );
  is_deeply( [ sort keys %$lock ], ['skills/foo'], 'the installed skill is committed to the lock' );
  is_deeply( [ sort keys %{ $lock->{'skills/foo'}{files} } ], [ 'skills/foo/.gitignore', 'skills/foo/SKILL.md' ], 'the lock owns both skill files' );

  my $status = $run_removed->( 'gone-default', 'status' );
  is_deeply(
    [ $status->{code}, decode_utf8_lossy( $status->{stdout} ), decode_utf8_lossy( $status->{stderr} ) ],
    [ 1, '', "skilletor: the current directory no longer exists; pass --project-dir <dir>\n" ],
    'without a project dir: exit 1, one actionable CLI error, no stack'
  );

  my $relative = $run_removed->( 'gone-relative', 'status', '--project-dir', 'project' );
  is_deeply(
    [ $relative->{code}, decode_utf8_lossy( $relative->{stdout} ), decode_utf8_lossy( $relative->{stderr} ) ],
    [ 1, '', "skilletor: the current directory no longer exists; pass --project-dir <dir>\n" ],
    'a relative project dir needs the cwd: the same error'
  );
};

# k254: a relative --project-dir names the project from the cwd. The sync keeps the scope's records
# under its absolute lock path, as every other run does – a relative key named no checkout once the
# cwd changed, and no later run could tell whether it was gone. As the reference's cli.test.ts.
subtest 'a relative --project-dir is the project at that path from the cwd, recorded absolute' => sub {
  my $base = tempdir->realpath;
  my ( $home, $src, $proj ) = map { path( $base, $_ ) } qw( home src proj );
  path( $home, '.claude' )->mkpath;
  path( $src, 'skills', 'foo' )->mkpath;
  path( $proj, '.claude' )->mkpath;
  path( $home, '.claude.json' )->spew_raw("{}\n");
  path( $src, 'skills', 'foo', 'SKILL.md' )->spew_raw("---\ndescription: foo\n---\nFOO\n");
  path( $home, '.claude', 'skilletor.json' )->spew_raw( js_stringify( js_ordered( sources => js_ordered( s => js_ordered( local => "$src" ) ) ) ) );
  path( $proj, '.claude', 'skilletor.json' )->spew_raw( js_stringify( js_ordered( install => js_ordered( skills => ['foo@s'] ) ) ) );

  my $bin = path( $FindBin::Bin, '..', 'script', 'skilletor' )->realpath;
  my $lib = path( $FindBin::Bin, '..', 'lib' )->realpath;
  my %env = %ENV;
  delete @env{qw( CLAUDE_CONFIG_DIR CLAUDE_PROJECT_DIR SKILLETOR_PROJECT_DIR HERMES_HOME )};
  @env{qw( HOME CODEX_HOME )} = ( "$home", path( $home, '.no-codex' )->stringify );
  my $r = run_command(
    cmd => [ 'sh', '-c', 'cd "$1" && shift && exec "$@"', 'sh', "$base", $^X, "-I$lib", "$bin", 'sync', '--project-dir', 'proj' ],
    env => \%env,
  );
  is_deeply( [ $r->{code}, decode_utf8_lossy( $r->{stderr} ) ], [ 0, '' ], 'synced' );
  ok( -e path( $proj, '.claude', 'skills', 'foo', 'SKILL.md' ), 'the skill installed in the project' );
  my $recorded = sub { [ keys %{ js_parse( path( $home, '.claude', 'skilletor', $_[0] )->slurp_raw ) } ] };
  my $lock_path = "$base/proj/.claude/skilletor.lock.json";
  is_deeply( [ $recorded->('sources-read.json'), $recorded->('render-inputs.json') ], [ [$lock_path], [$lock_path] ],
    'its records are keyed by the absolute lock path' );
};

done_testing;
