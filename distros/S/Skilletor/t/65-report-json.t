#!/usr/bin/env perl
# The reports as `skilletor sync|check|status --json` prints them (k171): the reference writes
# JSON.stringify(report, null, 2) – keys in the order its engine built them, not sorted – and
# passes every line through displaySafe. Skilletor::Report's report_json must give the same
# bytes. The key order is pinned here as engine.ts builds it; with node, every sync, check and
# status step of the shared conformance cases runs twice, in two copies of the case's machine –
# the reference's (src/ through maint/ts-run.mjs) and the port's – and the bytes of each step
# must be equal once the temp paths are placeholders. A `cli` step between them runs on each
# machine through that engine's CLI.
use strict;
use warnings;
use utf8;
use Test::More;
use FindBin;
use lib "$FindBin::Bin/lib";
use SkilletorTest qw( write_json );
use SkilletorTest::Conformance qw( abstract case_names read_case setup_case with_case_env );
use SkilletorTest::ParityCLI qw( clis run_cli skip_reason );

use IPC::Open2 qw( open2 );
use JSON::MaybeXS ();
use Path::Tiny qw( path tempdir );
use Skilletor::Engine;
use Skilletor::FSUtil qw( decode_utf8_lossy encode_text );
use Skilletor::JSON qw( js_ordered js_parse js_stringify );
use Skilletor::Report qw( report_json );

subtest 'report_json: JSON.stringify(report, null, 2), every line display-safe' => sub {
  my $r = js_ordered( scopes => [ js_ordered( scope => 'user', warnings => [ "bidi \x{202E}here", "del \x{7F} nl \n" ] ) ], error => 'x' );
  is( report_json($r), join( "\n",
      '{',
      '  "scopes": [',
      '    {',
      '      "scope": "user",',
      '      "warnings": [',
      '        "bidi \\u202ehere",',
      '        "del \\u007f nl \\n"',
      '      ]',
      '    }',
      '  ],',
      '  "error": "x"',
      '}' ), 'keys in their order, the bidi control and DEL escaped as JSON escapes, no final newline' );
  is_deeply( js_parse( report_json($r) ), $r, 'and it parses back to the same values' );
};

# The key order of engine.ts, pinned here too, so a machine without node still holds it: a user
# scope with an installed skill and agent, a hand-written skill in the way and an agent's missing
# briefing skill; a project scope with an untrusted source and a rules wildcard.
subtest "the reports' keys come in the reference's order" => sub {
  my $root = tempdir->realpath;
  my ( $home, $proj, $src ) = ( "$root/home", "$root/project", "$root/src" );
  my %files = (
    "$src/skills/a/SKILL.md"              => "---\ndescription: a\n---\na\n",
    "$src/skills/taken/SKILL.md"          => "---\ndescription: taken\n---\ntaken\n",
    "$src/agents/r.md"                    => "---\nname: r\ndescription: reviews\nbriefing:\n  skills: [a, nowhere]\n---\nReview.\n",
    "$src/rules/team-style.md"            => "Short.\n",
    "$home/.claude.json"                  => "{}\n",
    "$home/.claude/skills/taken/SKILL.md" => "mine\n",
  );
  write_json( $_, $files{$_} ) for keys %files;
  write_json( "$home/.claude/skilletor.json",
    { sources => { s => { local => $src } }, install => { skills => [ 'a@s', 'taken@s' ], agents => ['r@s'] } } );
  write_json( "$proj/.claude/skilletor.json", {
    sources => { team => { git => 'https://example.invalid/team.git' } },
    install => { skills => ['deploy@team'], rules => ['rule:*-style@s'] },
  } );
  my $e = Skilletor::Engine->new( home => $home, project_dir => $proj, codex_home => "$home/.codex",
    is_git_work_tree => sub { 0 }, git_tracked => sub { [] } );
  my $keys = sub { [ keys %{ $_[0] } ] };

  my $sync = $e->sync;
  my ( $user, $project ) = @{ $sync->{scopes} };
  my @scope_keys = qw( scope added updated removed unchanged skipped conflicts overwritten warnings trustRequests );
  is_deeply( $keys->($sync), ['scopes'], 'sync: scopes' );
  is_deeply( $keys->($user), [ @scope_keys, 'briefingMissing' ], 'a scope: the fixed keys, then what this run had to say' );
  is_deeply( $keys->($project), [ @scope_keys, 'gitignoreUpdated' ], 'the project scope: its commit hints last' );
  is_deeply( $keys->( $user->{added}[0] ), [qw( key type name source )], 'an item' );
  is_deeply( $keys->( $user->{conflicts}[0] ), ['path'], 'a conflict' );
  is_deeply( $keys->( $user->{briefingMissing}[0] ), [qw( key harness missing )], 'a missing briefing' );
  is_deeply( $keys->( $project->{trustRequests}[0] ), [qw( name kind url )], 'a trust request' );

  my $check = $e->check;
  is_deeply( $keys->($check), [qw( changed sources warnings trustRequests )], 'check: the fixed keys, then the trust requests' );
  is_deeply( $keys->( $check->{sources}[0] ), [qw( name scope changed )], 'a checked source' );
  is_deeply( $keys->( $check->{trustRequests}[0] ), [qw( scope name kind url )], 'a trust request names its scope first' );

  my $status = $e->status;
  my ( $su, $sp ) = @{ $status->{scopes} };
  is_deeply( $keys->($status), ['scopes'], 'status: scopes' );
  is_deeply( $keys->($su), [qw( scope targets declared orphans wildcards bundles trustRequests sourceVersions )], 'a status scope' );
  is_deeply( [ map { $keys->($_) } @{ $su->{declared} } ],
    [ [qw( key source installed )], [qw( key source installed )], [qw( key source installed briefingMissing )] ], 'declared items' );
  is_deeply( $keys->( $sp->{declared}[1] ), [qw( key source installed via )], 'one a wildcard installed' );
  is_deeply( $keys->( $sp->{wildcards}[0] ), [qw( type source entry installed )], 'a wildcard' );
  my $at_home = Skilletor::Engine->new( home => $home, project_dir => $home, codex_home => "$home/.codex",
    is_git_work_tree => sub { 0 }, git_tracked => sub { [] } );
  is_deeply( $keys->( $at_home->status ), [qw( scopes projectIsHome )], 'the project dir is the home: said after the scopes' );

  write_json( "$home/.claude/skilletor.json", { install => { skills => ['a@nowhere'] } } );
  is_deeply( $keys->( $e->sync ), [qw( scopes error )], 'a config error: sync' );
  is_deeply( $keys->( $e->check ), [qw( changed sources warnings error )], 'check' );
  is_deeply( $keys->( $e->status ), [qw( scopes error )], 'status' );
};

my @cases  = case_names();
my $runner = path( $FindBin::Bin, '..', 'maint', 'ts-run.mjs' );
my $src_ts = path( $FindBin::Bin, '..', 'src', 'engine.ts' );
my $why_not =
    !$runner->exists || !$src_ts->exists                                                ? 'needs the skilletor checkout (src/) and maint/ts-run.mjs'
  : !grep( { -x path( $_, 'node' ) } split /:/, $ENV{PATH} // '' )                     ? 'needs node'
  : !path( $FindBin::Bin, '..', 'node_modules', 'nunjucks' )->exists             ? "needs the reference's node_modules"
  : !@cases                                                                           ? 'needs the shared conformance cases (conformance/)'
  :                                                                                     skip_reason();    # the CLIs of the cli steps

sub ts {
  my ( $req ) = @_;
  my $pid = open2( my $out, my $in, 'node', "$runner" );
  binmode $in, ':raw';
  print {$in} encode_text( js_stringify($req) );
  close $in;
  local $/;
  my $text = <$out>;
  waitpid $pid, 0;
  die 'ts-run failed: '.( $text // '' ) unless defined $text && length $text;
  my $answer = js_parse( decode_utf8_lossy($text) );
  die 'ts-run: '.$answer->{error} if defined $answer->{error};
  return $answer->{result};
}

my %ENGINE_OP = map { ( $_ => 1 ) } qw( resolve sync check status );
my %COMPARED  = map { ( $_ => 1 ) } qw( sync check status );
my %CLI       = map { ( $_->[0] => $_->[1] ) } clis();

# The steps both engines run: the case's engine calls and the `cli` steps between them, up to the
# first step of another op or the first one the port skips; none of a case the port skips. The
# runners run every step on one machine, so what a cli step's command leaves – a sync's lock, state
# files, cache and installed files – the next engine call reads (24-conflicts-force: force after
# cli-sync). A cli step after the last engine call has nothing to feed.
sub steps_of {
  my ( $c ) = @_;
  my $perl = ( $c->{engines} // {} )->{perl} // {};
  return () if defined $perl->{skip};
  my @steps;
  for my $step ( @{ $c->{steps} } ) {
    last unless $ENGINE_OP{ $step->{op} } || $step->{op} eq 'cli';
    last if defined( ( ( $perl->{steps} // {} )->{ $step->{id} } // {} )->{skip} );
    push @steps, $step;
  }
  pop @steps while @steps && $steps[-1]{op} eq 'cli';
  return @steps;
}

# A `cli` step on one engine's machine, through that engine's CLI: the reference's bundle or
# bin/skilletor (SkilletorTest::ParityCLI, as t/54 runs them). Only what it leaves counts here.
sub run_cli_step {
  my ( $which, $m, $step ) = @_;
  path( $m->{tmp}, 'cwd' )->mkpath;    # its cwd without a project (README: cli)
  my $got = run_cli( $CLI{$which}, $m, $step );
  die "step $step->{id}: the $which CLI $got->{failed}\n" if defined $got->{failed};
  return undef;
}

sub run_case {
  my ( $name ) = @_;
  my @steps = steps_of( read_case($name) );
  plan skip_all => 'no sync, check or status step to compare' unless grep { $COMPARED{ $_->{op} } } @steps;

  my $ts_machine = setup_case($name);
  my @ts_out = with_case_env(
    $ts_machine,
    sub {
      my ( @out, @batch );
      my $flush = sub {    # the engine calls since the last cli step, on one context
        push @out, @{ ts( {
          op => 'steps', home => $ts_machine->{home}, projectDir => $ts_machine->{project},
          host => { name => 'conformance', os => 'linux' }, user => { name => 'conformance', home => $ts_machine->{home} },
          steps => [ map { js_ordered( op => $_->{op}, scope => $_->{scope} // 'all', force => $_->{force} ? JSON::MaybeXS::true() : JSON::MaybeXS::false() ) } @batch ],
        } ) } if @batch;
        @batch = ();
      };
      for my $step (@steps) {
        if ( $step->{op} ne 'cli' ) { push @batch, $step; next }
        $flush->();
        push @out, run_cli_step( ts => $ts_machine, $step );
      }
      $flush->();
      @out;
    }
  );

  my $m = setup_case($name);
  my @perl_out = with_case_env(
    $m,
    sub {
      my $sk = Skilletor::Engine->new(
        home             => $m->{home},
        ( $m->{project} ? ( project_dir => $m->{project} ) : () ),
        state_root       => "$m->{home}/.claude/skilletor",
        codex_home       => "$m->{home}/.codex",
        hermes_home      => "$m->{home}/.hermes",
        require_harness  => 1,
        is_git_work_tree => sub { 0 },
        git_tracked      => sub { [] },
        host             => { name => 'conformance', os => 'linux' },
        user             => { name => 'conformance', home => $m->{home} },
      );
      map {
        my %opts = ( scope => $_->{scope} // 'all' );
        my $report =
            $_->{op} eq 'cli'     ? run_cli_step( perl => $m, $_ )
          : $_->{op} eq 'resolve' ? $sk->resolve(%opts)
          : $_->{op} eq 'sync'    ? $sk->sync( %opts, force => $_->{force} ? 1 : 0 )
          : $_->{op} eq 'check'   ? $sk->check(%opts)
          :                         $sk->status(%opts);
        $COMPARED{ $_->{op} } ? report_json($report) : undef;
      } @steps;
    }
  );

  for my $i ( 0 .. $#steps ) {
    next unless $COMPARED{ $steps[$i]{op} };
    is( abstract( $perl_out[$i], $m ), abstract( $ts_out[$i], $ts_machine ), "step $steps[$i]{id}: the --json bytes" );
  }
}

SKIP: {
  skip $why_not, 1 if defined $why_not;
  for my $name (@cases) {
    subtest "conformance: $name" => sub { run_case($name) };
  }
}

done_testing;
