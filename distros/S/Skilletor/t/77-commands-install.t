#!/usr/bin/env perl
# Skilletor::Commands::install's pieces no conformance case reaches (cases 130 to 139 hold its
# entries, refusals and, without a terminal, a bundle's missing sources, to the reference's
# bytes): the questions it asks about those sources when it has a prompter – injected here, as
# commands.test.ts injects its own – and the sync lock it plans under (k74): it waits for a held
# one before it fetches or edits, and asks with the lock free. Then the CLI's prompter: none
# without a terminal on stdin and stderr, and on a pty (Linux, util-linux script) the answer
# taken and Ctrl+D aborting with nothing changed.
use strict;
use warnings;
use utf8;
use Test::More;
use FindBin;
use lib "$FindBin::Bin/lib";
use SkilletorTest qw( make_repo write_json );

use Cwd ();
use Encode ();
use POSIX ();
use Path::Tiny qw( path tempdir );
use Time::HiRes ();
use Skilletor::CLI;
use Skilletor::Commands;
use Skilletor::Engine;
use Skilletor::JSON qw( js_parse js_stringify );
use Skilletor::Process qw( run_command );
use Skilletor::State;

# A machine with Claude Code, a git repository `peter` of one rule p-one (served at $url), and a
# local source `mine` whose bundle perl holds $rules; the user config declares `mine` and %sources.
sub machine {
  my ( $rules, %sources ) = @_;
  my $tmp  = Cwd::realpath( tempdir() );
  my $home = "$tmp/home";
  my $url  = 'file://'.make_repo( "$tmp/peter", 'rules/p-one.md' => "---\ndescription: one\n---\nOne.\n" );
  my $mine = "$tmp/mine";
  path("$mine/rules/r1.md")->touchpath->spew_raw("---\ndescription: r1\n---\nR1.\n");
  path("$mine/bundles/perl.yaml")->touchpath->spew_raw( "description: P\nrules: [".( $rules =~ s/\$url/$url/gr )."]\n" );
  path("$home/.claude.json")->touchpath->spew_raw('{}');
  path("$tmp/project/.claude")->mkpath;
  my $user = write_json( "$home/.claude/skilletor.json", { sources => { mine => { local => $mine }, %sources } } );
  my $engine = Skilletor::Engine->new( home => $home, project_dir => "$tmp/project", claude_config_dir => '', codex_home => "$home/.codex",
    is_git_work_tree => sub { 0 }, git_tracked => sub { [] } );
  return { tmp => $tmp, home => $home, url => $url, mine => $mine, user => $user, engine => $engine, project => "$tmp/project/.claude/skilletor.json" };
}

# A prompter answering from a list ("n" once it is used up) and recording the questions.
sub answers {
  my ( @list ) = @_;
  my @questions;
  return ( \@questions, sub { push @questions, $_[0]; return shift(@list) // 'n' } );
}

sub json_of { js_parse( path( $_[0] )->slurp_raw ) }
sub added   { [ map { "$_->{key}\@$_->{source}" } @{ $_[0]{scopes}[0]{added} } ] }

sub question {
  my ( $url, $name ) = @_;
  return "bundle perl needs a source you don't have yet: $url \x{2192} $url \x{2014} add it as [$name]? (name, or n to skip)";
}

sub trusted {
  my ( $m, $name ) = @_;
  return Skilletor::State->new( root => $m->{engine}->state_root )->is_trusted( $name, { kind => 'git', address => $m->{url}, origin => 'project' } );
}

subtest 'asked once per missing source: the default adds and trusts it as add does, then installs from it' => sub {
  my $m = machine('"p-*@$url"');
  my ( $questions, $prompt ) = answers('');
  my $r = Skilletor::Commands::install( $m->{engine}, items => ['bundle:perl@mine'], prompt => $prompt );
  is_deeply( $questions, [ question( $m->{url}, 'peter' ) ], 'one question, the derived name proposed' );
  my $cfg = json_of( $m->{user} );
  is_deeply( $cfg->{sources}{peter}, { git => $m->{url} }, 'added under that name' );
  is_deeply( $cfg->{install}, { bundles => ['perl@mine'] }, 'the bundle declared' );
  ok( trusted( $m, 'peter' ), 'trusted' );
  is_deeply( added($r), ['rules/p-one@peter'], 'installed from it' );
};

subtest 'a taken name is refused and asked again; n skips; --project adds to the project' => sub {
  my $m = machine( 'p-one@$url', taken => { git => 'https://example.com/other' } );
  my ( $questions, $prompt ) = answers( 'taken', 'pete' );
  Skilletor::Commands::install( $m->{engine}, items => ['bundle:perl@mine'], project => 1, prompt => $prompt );
  is( scalar @$questions, 2, 'asked twice' );
  is( $questions->[1], '"taken" is already a source with another address (https://example.com/other). '.question( $m->{url}, 'peter' ),
    'the second time with a note naming the address' );
  my $proj = json_of( $m->{project} );
  is_deeply( $proj->{sources}, { pete => { git => $m->{url} } }, 'added to the project config' );
  is_deeply( $proj->{install}, { bundles => ['perl@mine'] }, 'the bundle declared there' );
  ok( !exists json_of( $m->{user} )->{sources}{pete}, 'not to the user config' );

  ( $questions, $prompt ) = answers('n');
  my $r = Skilletor::Commands::install( $m->{engine}, items => ['bundle:perl@mine'], prompt => $prompt );
  is( scalar @$questions, 1, 'user scope: asked again, it does not see the project source' );
  my $cfg = json_of( $m->{user} );
  ok( !exists $cfg->{sources}{pete}, 'n: nothing added' );
  is_deeply( $cfg->{install}, { bundles => ['perl@mine'] }, 'the bundle declared all the same' );
  like( join( "\n", @{ $r->{scopes}[0]{warnings} } ), qr/bundle perl\@mine needs/, "the sync warns of the member it cannot serve" );
};

subtest "k102: a name the target config already has is neither proposed nor written over" => sub {
  my $tmp = Cwd::realpath( tempdir() );
  my $checkout = "$tmp/peter-checkout";
  path("$checkout/rules/x-one.md")->touchpath->spew_raw("---\ndescription: x\n---\nX.\n");
  my $m = machine( 'p-one@$url', peter => { local => $checkout } );
  my $proj_raw = js_stringify( { sources => { peter => { git => $m->{url} } } }, 2 )."\n";
  path( $m->{project} )->spew_raw($proj_raw);
  my ( $questions, $prompt ) = answers( 'peter', '' );
  my $r = Skilletor::Commands::install( $m->{engine}, items => ['bundle:perl@mine'], prompt => $prompt );
  my $question = question( $m->{url}, 'peter-2' );
  is_deeply( $questions, [ $question, qq{"peter" is already a source with another address (local $checkout). $question} ],
    'peter-2 proposed; peter refused, naming the entry of the user config' );
  is_deeply( json_of( $m->{user} )->{sources},
    { mine => { local => $m->{mine} }, peter => { local => $checkout }, 'peter-2' => { git => $m->{url} } }, 'peter-2 added, peter kept' );
  is( path( $m->{project} )->slurp_raw, $proj_raw, 'the project config byte-identical' );
  ok( trusted( $m, 'peter-2' ), 'peter-2 trusted' );
  is_deeply( added($r), ['rules/p-one@peter-2'], 'installed from peter-2' );
};

subtest 'k95: the prompt refuses what config load refuses and takes what it loads' => sub {
  my $m = machine('p-one@$url');
  my ( $questions, $prompt ) = answers( 'a b', '_x', 'ok.name' );
  my $r = Skilletor::Commands::install( $m->{engine}, items => ['bundle:perl@mine'], prompt => $prompt );
  my $question = question( $m->{url}, 'peter' );
  is_deeply( $questions, [ $question, qq{"a b" is not a valid source name. $question}, qq{"_x" is not a valid source name. $question} ],
    'each refused name asked again with a note' );
  is_deeply( json_of( $m->{user} )->{sources}, { mine => { local => $m->{mine} }, 'ok.name' => { git => $m->{url} } }, 'ok.name added' );
  ok( !defined $r->{error}, 'the sync loads it' );
  is_deeply( added($r), ['rules/p-one@ok.name'], 'and installs from it' );
};

subtest 'k115: an entry address config load would refuse is the bundle error, before any question' => sub {
  my $m = machine('r1, x@http://host/x.tar.gz');
  my $raw = path( $m->{user} )->slurp_raw;
  my ( $questions, $prompt ) = answers('');
  my $err = eval { Skilletor::Commands::install( $m->{engine}, items => [ 'bundle:perl@mine', 'rule:r1@mine' ], prompt => $prompt ); 1 } ? undef : $@;
  isa_ok( $err, 'Skilletor::Error::Command' );
  is( $err && $err->message, 'mine: bundle perl: bundles/perl.yaml: rules: "x@http://host/x.tar.gz" cannot be added as a source: '
      .'sources.host.url "http://host/x.tar.gz" must be an https:// URL', "the bundle's error" );
  is_deeply( $questions, [], 'no question asked' );
  is( path( $m->{user} )->slurp_raw, $raw, 'the user config byte-identical' );
  ok( !-e $m->{engine}->state_root.'/trust.json', 'nothing trusted' );
};

subtest 'a source configured under any name is not asked for' => sub {
  my $m = machine('p-one@$url');
  my $cfg = json_of( $m->{user} );
  $cfg->{sources}{whatever} = { git => $m->{url} };
  write_json( $m->{user}, $cfg );
  my ( $questions, $prompt ) = answers();
  Skilletor::Commands::install( $m->{engine}, items => ['bundle:perl@mine'], prompt => $prompt );
  is_deeply( $questions, [], 'no question' );
  ok( -e "$m->{home}/.claude/rules/.local.p-one.md", 'installed from the configured source' );
};

subtest 'k74: install plans under the sync lock, then asks and syncs without holding it' => sub {
  plan skip_all => 'needs fork' if $^O eq 'MSWin32';
  my $m = machine('p-one@$url');
  my $cfg = json_of( $m->{user} );
  $cfg->{sources} = { peter => { git => $m->{url} } };
  write_json( $m->{user}, $cfg );
  my $state = $m->{engine}->state_root;
  my $out   = path("$m->{tmp}/install.json");
  my ( $pid, $waited, $fetched, $edited );
  Skilletor::State->new( root => $state )->with_lock(
    sub {
      $pid = fork // die "fork: $!";
      if ( !$pid ) {
        my $ok = eval {
          my $r = Skilletor::Commands::install( $m->{engine}, items => ['p-one@peter'] );
          path("$out.tmp")->spew_raw( js_stringify( { error => $r->{error}, added => added($r) } ) );
          rename "$out.tmp", "$out" or die "rename: $!";
          1;
        };
        POSIX::_exit( $ok ? 0 : 1 );
      }
      Time::HiRes::sleep(0.3);
      $waited  = !-e "$out";
      $fetched = -e $m->{engine}->cache_root;
      $edited  = exists json_of( $m->{user} )->{install};
    }
  );
  waitpid $pid, 0;
  is( $?, 0, 'install ran' );
  ok( $waited,   'it had not returned while the lock was held' );
  ok( !$fetched, 'nothing fetched meanwhile' );
  ok( !$edited,  'the config untouched meanwhile' );
  is_deeply( js_parse( $out->slurp_raw ), { error => undef, added => ['rules/p-one@peter'] }, 'once free: installed, its own sync got the lock' );

  $cfg = json_of( $m->{user} );
  $cfg->{sources}{mine} = { local => $m->{mine} };
  write_json( $m->{user}, $cfg );
  my $paul = 'file://'.make_repo( "$m->{tmp}/paul", 'rules/q-one.md' => "---\ndescription: q\n---\nQ.\n" );
  path("$m->{mine}/bundles/perl.yaml")->spew_raw("description: P\nrules: [q-one\@$paul]\n");
  my @held;
  Skilletor::Commands::install( $m->{engine}, items => ['bundle:perl@mine'], prompt => sub { push @held, -e "$state/sync.lock" ? 1 : 0; 'n' } );
  is_deeply( \@held, [0], 'asked once, with the lock free' );
};

subtest "the CLI's prompter: none unless stdin is a terminal" => sub {
  open( my $null, '<', '/dev/null' ) or die "/dev/null: $!";
  local *STDIN = $null;
  ok( !defined Skilletor::CLI::_tty_prompter(), 'stdin not a terminal: no prompter' );
};

# The CLI on a pty, as a user at a terminal: util-linux script runs it, its stdin fed from a pipe.
subtest "on a pty: the question on the terminal, the answer taken; Ctrl+D aborts, nothing changed" => sub {
  plan skip_all => 'needs Linux' unless $^O eq 'linux';
  my $script = run_command( cmd => [ 'script', '--version' ] );
  plan skip_all => 'needs util-linux script' unless ( $script->{stdout} // '' ) =~ /util-linux/;
  my $quote = sub { my $s = shift; $s =~ s/'/'\\''/g; return "'$s'" };
  my @perl = ( $^X, map { "-I$_" } grep { !ref } @INC );
  my $pty = sub {
    my ( $m, $input, @argv ) = @_;
    my $r = run_command(
      cmd   => [ 'script', '-qec', join( ' ', map { $quote->($_) } @perl, @argv ), '/dev/null' ],
      stdin => $input,
      cwd   => "$m->{tmp}/project",
      env   => { %ENV, HOME => $m->{home}, CODEX_HOME => "$m->{home}/.codex", SHELL => '/bin/sh' },
      timeout_ms => 60_000,
    );
    return { code => $r->{code}, out => Encode::decode( 'UTF-8', $r->{stdout} ) =~ s/\r\n/\n/gr };
  };
  my $probe = 'print defined Skilletor::CLI::_tty_prompter() ? "prompter" : "none"';
  like( $pty->( machine('p-one@$url'), '', '-MSkilletor::CLI', '-e', $probe )->{out}, qr/\Aprompter\z/, 'stdin and stderr a terminal: a prompter' );
  like( $pty->( machine('p-one@$url'), '', '-e', "use Skilletor::CLI; open STDERR, '>', '/dev/null'; $probe" )->{out}, qr/\Anone\z/,
    'stderr not a terminal: none' );

  my $bin = "$FindBin::Bin/../script/skilletor";
  my $m = machine('p-one@$url');
  my $r = $pty->( $m, "\n", $bin, 'install', 'bundle:perl@mine' );
  is( $r->{code}, 0, 'the answer: exit 0' );
  # The pty echoes the answer when it arrives, which is before the question is asked.
  like( $r->{out}, qr/\Q@{[ question( $m->{url}, 'peter' ) ]}\E /, 'the question on the terminal, a blank after it' );
  like( $r->{out}, qr/skilletor: user scope\n  \+ rules\/p-one \(active after \/reload-plugins or restart\)\n\z/, "then the sync's text" );
  is_deeply( json_of( $m->{user} )->{sources}{peter}, { git => $m->{url} }, 'the default name added' );

  $m = machine('p-one@$url');
  my $raw = path( $m->{user} )->slurp_raw;
  $r = $pty->( $m, "\x04", $bin, 'install', 'bundle:perl@mine' );
  is( $r->{code}, 1, 'Ctrl+D: exit 1' );
  like( $r->{out}, qr/\Q(name, or n to skip)\E skilletor: Aborted with Ctrl\+D\n\z/, "the reference's message after the question" );
  is( path( $m->{user} )->slurp_raw, $raw, 'the user config byte-identical' );
  ok( !-e $m->{engine}->state_root.'/trust.json', 'nothing trusted' );
};

done_testing;
