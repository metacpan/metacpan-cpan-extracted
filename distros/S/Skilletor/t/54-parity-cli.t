#!/usr/bin/env perl
# CLI parity on one machine (k187): the reference CLI (node dist/skilletor.js) and bin/skilletor
# run the same steps from the same pristine machine, in the very same paths, and must leave the
# same bytes – exit code, stdout, stderr, and every file a run may change: installed trees, the
# lock, the state files (render-inputs.json, whose hash covers absolute paths, sources-read.json,
# unreached.json, trust, the hooks' marks and records, the source cache's checkout), the
# directories and the executable bits (SkilletorTest::ParityCLI says what it leaves out and
# normalises, and why). It covers what conformance/'s golden files cannot pin:
# - the conformance cases' steps through both CLIs, their state files included;
# - git's failure wording, which a warning quotes;
# - the real host and user in templates;
# - both CLIs sharing one sync lock: one holds it, the other's sync and SessionStart wait for it,
#   or time out with the reference's words.
# The case format is conformance/README.md's; a case's engine op runs as its command, --json.
# Needs node and the reference's bundle; skips without either, naming which.
use strict;
use warnings;
use Test::More;
use FindBin;
use lib "$FindBin::Bin/lib";
use SkilletorTest::ParityCLI qw( skip_reason clis start_cli finish_cli run_cli save_machine restore_machine snapshot drive wait_for );

BEGIN {
  my $why = skip_reason();
  plan skip_all => $why if defined $why;
}

use Cwd ();
use Path::Tiny qw( path tempdir );
use Sys::Hostname ();
use SkilletorTest qw( git_ok make_repo write_json );
use SkilletorTest::Conformance qw( case_names read_case setup_case );
use Skilletor::FSUtil qw( decode_utf8_lossy encode_text );
use Skilletor::JSON qw( js_parse );

my %CLI = map { ( $_->[0] => $_->[1] ) } clis();

# The port's step against the reference's: exit code, both streams, the files after it.
sub same_step {
  my ( $what, $ts, $perl ) = @_;
  for my $r ( [ reference => $ts ], [ port => $perl ] ) {
    next unless defined $r->[1]{result}{failed};
    return fail("$what: the $r->[0]'s CLI $r->[1]{result}{failed}");
  }
  is( $perl->{result}{exit},   $ts->{result}{exit},   "$what: the exit code" );
  is( $perl->{result}{stdout}, $ts->{result}{stdout}, "$what: stdout" );
  is( $perl->{result}{stderr}, $ts->{result}{stderr}, "$what: stderr" );
  same_snapshot( $what, $ts->{snap}, $perl->{snap} );
}

sub same_snapshot {
  my ( $what, $want, $got ) = @_;
  is_deeply( [ sort keys %{ $got->{files} } ], [ sort keys %{ $want->{files} } ], "$what: the same files" );
  is_deeply( $got->{dirs},        $want->{dirs},        "$what: the same directories" );
  is_deeply( $got->{executables}, $want->{executables}, "$what: the same executable bits" );
  my @differ = grep { exists $got->{files}{$_} && $got->{files}{$_} ne $want->{files}{$_} } sort keys %{ $want->{files} };
  ok( !@differ, "$what: every file the same bytes" )
    or diag map { "$_, the reference's:\n".decode_utf8_lossy( $want->{files}{$_} )."\n$_, the port's:\n".decode_utf8_lossy( $got->{files}{$_} )."\n" } @differ;
}

# Both CLIs through the same steps, each from the machine as saved.
sub both {
  my ( $m, $steps ) = @_;
  my $saved = save_machine($m);
  my %runs;
  for my $name (qw( ts perl )) {
    restore_machine( $m, $saved );
    $runs{$name} = drive( $m, $CLI{$name}, $steps );
  }
  return \%runs;
}

sub same_runs {
  my ( $runs, $todo ) = @_;
  for my $i ( 0 .. $#{ $runs->{ts} } ) {
    local $TODO = $todo->{ $runs->{ts}[$i]{id} } if $todo;
    same_step( "step $runs->{ts}[$i]{id}", $runs->{ts}[$i], $runs->{perl}[$i] );
  }
}

#### The conformance cases ##############################################

# A case's step as a command line: a `cli` step as it is; an engine op as its command with
# --json, from the step's default cwd as a `cli` step runs (the CLI takes its project from it).
# A resolve has no command: it only fills the cache, which the next sync fills itself.
sub cli_step {
  my ( $step ) = @_;
  return $step if $step->{op} eq 'cli';
  return () if $step->{op} eq 'resolve';
  my @argv = ( $step->{op}, '--scope', $step->{scope} // 'all', ( $step->{op} eq 'sync' && $step->{force} ? '--force' : () ), '--json' );
  return { id => $step->{id}, argv => \@argv };
}

# The cases run here: each for state its golden trees leave out (README: trees, the state dir)
# and this test's own machines below do not reach. Every other case is t/60-conformance.t's alone,
# which holds the Perl CLI to the reference's bytes already; every case through both CLIs costs
# over three minutes. A case named here that is gone fails.
my %CASES = (
  '24-conflicts-force'        => 'unreached.json of lasting conflicts, then --force adopting them',
  '32-claude-config-dir-user' => 'the state dir under CLAUDE_CONFIG_DIR',
  '52-hook-pending-report'    => 'pending-report.json: the background sync leaves it, the prompt takes it',
  '60-hook-cwd-changed'       => 'session-cwd.json and the sync of a move',
  '64-hook-post-tool-use'     => 'a seeded session-cwd.json, read and rewritten by PostToolUse',
);

subtest 'conformance cases, through both CLIs' => sub {
  my %known = map { ( $_ => 1 ) } case_names();
  for my $name ( sort keys %CASES ) {
    subtest "$name: $CASES{$name}" => sub {
      plan skip_all => 'no conformance cases (conformance/)' unless %known;
      return fail("no case $name in conformance/cases") unless $known{$name};
      my $c = read_case($name);
      my $perl = ( $c->{engines} // {} )->{perl} // {};
      plan skip_all => $perl->{skip} if defined $perl->{skip};
      my %variant = %{ $perl->{steps} // {} };
      my @steps = map { cli_step($_) } grep { !defined( ( $variant{ $_->{id} } // {} )->{skip} ) } @{ $c->{steps} };
      my $r = setup_case($name);
      my $m = { tmp => $r->{tmp}, home => $r->{home}, project => $r->{project}, env => $r->{env} };
      path( $r->{tmp}, 'cwd' )->mkpath;
      # A step the port expects otherwise (engines.perl.steps.<id>.expected) is a known divergence.
      my %todo = map { ( $_ => "engines.perl: $variant{$_}{expected}" ) } grep { defined $variant{$_}{expected} } keys %variant;
      same_runs( both( $m, \@steps ), \%todo );
    };
  }
};

#### A machine of this test's own #######################################

sub skill { "---\ndescription: $_[0]\n---\nbody of $_[0]\n" }

# A fresh machine: ${TMP} with home/ (Claude Code in use) and cwd/, no project yet.
sub machine {
  my $tempdir = tempdir( 'skilletor-parity-cli-XXXXXX', TMPDIR => 1 );
  my $tmp = Cwd::realpath("$tempdir");
  my $m = { tempdir => $tempdir, tmp => $tmp, home => "$tmp/home", env => {} };
  path( $m->{home}, '.claude' )->mkpath;
  path( $m->{home}, '.claude.json' )->spew_raw("{}\n");
  path( $tmp, 'cwd' )->mkpath;
  return $m;
}

# A git config file in ${TMP}: each address reached through another (insteadOf), plus $extra.
sub gitconfig {
  my ( $m, $file, $map, $extra ) = @_;
  my $text = $extra // '';
  $text .= qq([url "$map->{$_}"]\n\tinsteadOf = $_\n) for sort keys %$map;
  path( $m->{tmp}, $file )->spew_raw( encode_text($text) );
}

# The render context's host and user as Node's os module names them on this machine.
my $HOST = Sys::Hostname::hostname();
my $OS   = { linux => 'linux', darwin => 'darwin', MSWin32 => 'win32' }->{$^O} // $^O;
my $USER = $^O eq 'MSWin32' ? $ENV{USERNAME} : scalar getpwuid $>;

subtest 'add and trust write byte-identical trust state' => sub {
  my $m = machine();
  my $tmp = $m->{tmp};
  my $added = path( $tmp, 'added-source' );
  my $project_source = path( $tmp, 'project-source' );
  $added->mkpath;
  $project_source->mkpath;
  $added = $added->realpath;
  $project_source = $project_source->realpath;
  $m->{project} = "$tmp/project";
  path( $m->{project}, '.claude' )->mkpath;
  write_json( "$m->{project}/.claude/skilletor.json", {
    sources => { project_local => { local => "$project_source" } },
  } );

  my $runs = both( $m, [
    { id => 'add local source', argv => [ 'add', 'extra', '${TMP}/added-source' ] },
    { id => 'trust project source', argv => [ 'trust', 'project_local' ] },
  ] );
  same_runs($runs);

  my $trust = 'home/.claude/skilletor/trust.json';
  for my $i ( 0, 1 ) {
    my $step = $runs->{ts}[$i]{id};
    my $want = $runs->{ts}[$i]{snap}{files}{$trust};
    my $got  = $runs->{perl}[$i]{snap}{files}{$trust};
    ok( defined $want, "$step: the reference wrote trust.json" );
    ok( defined $got,  "$step: the port wrote trust.json" );
    is( $got, $want, "$step: trust.json is byte-identical" ) if defined $want && defined $got;
  }

  my $after_add = js_parse( decode_utf8_lossy( $runs->{ts}[0]{snap}{files}{$trust} ) );
  is_deeply( $after_add, { extra => { kind => 'local', address => "$added" } },
    'add trusted exactly the canonical local backend' );
  my $after_trust = js_parse( decode_utf8_lossy( $runs->{ts}[1]{snap}{files}{$trust} ) );
  is_deeply( $after_trust, {
    extra         => { kind => 'local', address => "$added" },
    project_local => { kind => 'local', address => "$project_source" },
  }, 'trust appended exactly the project source backend' );
};

subtest 'git failures, real host and user, the state files' => sub {
  my $m = machine();
  my $tmp = $m->{tmp};
  make_repo(
    "$tmp/git/good",
    'skills/lint/SKILL.md'      => skill('lint'),
    'rules/style.md'            => "Short sentences.\n",
    'skills/whoami/SKILL.md.njk' => "---\ndescription: who and where\n---\n"
      ."{{ host.name }} {{ host.os }} {{ user.name }} {{ user.home }}\n"
      ."{{ scope }}/{{ harness }} into {{ target.dir }}\n"
      ."{% if project is defined %}{{ project.dir }} {{ project.name }} {{ project.git_remote }}{% else %}no project{% endif %}\n",
  );
  my %reach = (
    'https://parity.invalid/good.git' => "file://$tmp/git/good",
    'https://parity.invalid/gone.git' => "file://$tmp/git/gone",    # no such repository
  );
  gitconfig( $m, 'gitconfig', \%reach );
  # The good source moved away: a fetch fails, its cache is used.
  gitconfig( $m, 'gitconfig-moved', { %reach, 'https://parity.invalid/good.git' => "file://$tmp/git/moved" } );
  path( $tmp, 'no-git' )->mkpath;    # a PATH without git
  path( $tmp, 'mute-git', 'git' )->touchpath->spew_raw("#!/bin/sh\nexit 1\n");    # a git that fails without a word
  chmod 0755, "$tmp/mute-git/git";

  write_json( "$m->{home}/.claude/skilletor.json", {
    sources => {
      good   => { git => 'https://parity.invalid/good.git' },
      gone   => { git => 'https://parity.invalid/gone.git' },
      badref => { git => 'https://parity.invalid/good.git', ref => 'nope' },    # a ref the remote lacks
    },
    install => { skills => [ 'lint@good', 'whoami@good', 'x@gone', 'y@badref' ], rules => ['style@good'] },
  } );
  $m->{project} = "$tmp/project";
  path( $m->{project}, '.claude' )->mkpath;
  git_ok( $m->{project}, 'init', '-q', '-b', 'main' );
  git_ok( $m->{project}, 'remote', 'add', 'origin', 'https://example.invalid/team/app.git' );    # a render input
  write_json( "$m->{project}/.claude/skilletor.json", { install => { skills => [ 'whoami@good', 'lint@good' ] }, vars => { team => 'core' } } );
  path( $m->{project}, '.claude', 'skills', 'lint', 'SKILL.md' )->touchpath->spew_raw("mine\n");    # a lasting conflict: unreached
  # Check marks earlier sessions left (k255): a project dir that is gone, a relative key, a live
  # one; SessionStart's mark drops the first two in both CLIs.
  write_json( "$m->{home}/.claude/skilletor/last-check.json", { "$tmp/gone/proj" => 1, 'rel/proj' => 2, "$tmp/cwd" => 3 } );

  my $moved = { GIT_CONFIG_GLOBAL => '${TMP}/gitconfig-moved' };
  my $runs = both( $m, [
    { id => 'sync',          argv => ['sync'] },
    { id => 'sync --json',   argv => [ 'sync', '--json' ] },
    { id => 'check',         argv => ['check'] },
    { id => 'check --json',  argv => [ 'check', '--json' ] },
    { id => 'status',        argv => ['status'] },
    { id => 'sync, moved',   argv => ['sync'], env => $moved },
    { id => 'check, moved',  argv => [ 'check', '--json' ], env => $moved },
    { id => 'session-start, moved', argv => [ 'hook', 'session-start' ], env => { %$moved, CLAUDE_PROJECT_DIR => '${PROJECT}' },
      stdin => { session_id => 'parity', cwd => '${PROJECT}', source => 'startup' } },
    { id => 'sync, no git',   argv => ['sync'], env => { PATH => '${TMP}/no-git' } },
    { id => 'sync, mute git', argv => [ 'sync', '--json' ], env => { PATH => '${TMP}/mute-git' } },
  ] );

  # The scenario did what it claims, in the reference's run.
  my %ts = map { ( $_->{id} => $_ ) } @{ $runs->{ts} };
  my $first = decode_utf8_lossy( $ts{sync}{result}{stdout} );
  like( $first, qr/fatal: '\Q$tmp\E\/git\/gone' does not appear to be a git repository/, 'a missing repository: git\'s words' );
  like( $first, qr/couldn't find remote ref nope/,                                       'a missing ref: git\'s words' );
  like( decode_utf8_lossy( $ts{'sync, moved'}{result}{stdout} ), qr/git fetch failed for https:\/\/parity\.invalid\/good\.git, using cache/,
    'an unreachable source with a cache: served from it' );
  like( decode_utf8_lossy( $ts{'sync, no git'}{result}{stdout} ),   qr/spawn git ENOENT/,             'no git on PATH' );
  like( decode_utf8_lossy( $ts{'sync, mute git'}{result}{stdout} ), qr/Command failed: git /,         'a git that says nothing' );
  my $snap = $ts{sync}{snap}{files};
  is( $snap->{'home/.claude/skills/whoami/SKILL.md'},
    "---\ndescription: who and where\n---\n$HOST $OS $USER $m->{home}\nuser/claude into $m->{home}/.claude\nno project\n",
    'the user scope\'s template: this machine\'s host and user' );
  is( $snap->{'project/.claude/skills/whoami/SKILL.md'},
    "---\ndescription: who and where\n---\n$HOST $OS $USER $m->{home}\nproject/claude into $m->{project}/.claude\n"
      ."$m->{project} project https://example.invalid/team/app.git\n",
    'the project scope\'s: the project, its remote' );
  ok( exists $snap->{"home/.claude/skilletor/$_"}, "the reference wrote $_" )
    for qw( render-inputs.json sources-read.json unreached.json );
  ok( exists $ts{'session-start, moved'}{snap}{files}{"home/.claude/skilletor/$_"}, "its SessionStart wrote $_" )
    for qw( last-check.json session-cwd.json );
  is( $ts{'session-start, moved'}{snap}{files}{'home/.claude/skilletor/last-check.json'},
    qq({\n  "$tmp/cwd": 3,\n  "$m->{project}": "<step session-start, moved>"\n}\n),
    'its SessionStart dropped the marks of the gone project and the relative key, kept the live one' );

  same_runs($runs);
};

#### One sync lock ######################################################

subtest 'one sync lock: a CLI holds it, the other waits or times out' => sub {
  my $m = machine();
  my $tmp = $m->{tmp};
  BAIL_OUT("a temp path ext:: cannot carry: $tmp") if $tmp =~ /[\s%;"\\]/;
  make_repo( "$tmp/git/slow", 'skills/lint/SKILL.md' => skill('lint') );
  my $url = 'https://parity.invalid/slow.git';
  gitconfig( $m, 'gitconfig', { $url => "file://$tmp/git/slow" } );
  # A holder's fetch takes $s seconds: git runs the remote's upload-pack through ext::, after a
  # sleep. The holder takes the sync lock before it fetches and keeps it until its sync is done.
  for my $s ( 2, 8 ) {
    gitconfig( $m, "gitconfig-slow-$s", { $url => "ext::sh -c sleep% $s;exec% git-upload-pack% $tmp/git/slow" },
      qq([protocol "ext"]\n\tallow = always\n) );
  }
  write_json( "$m->{home}/.claude/skilletor.json", { sources => { slow => { git => $url } }, install => { skills => ['lint@slow'] } } );
  my $saved = save_machine($m);
  my $state = "$m->{home}/.claude/skilletor";
  my $owner = "$state/sync.lock/owner.json";

  # $holder syncs with a fetch of $s seconds; once it holds the lock, $waiter's sync and
  # SessionStart start at once. The owner record has its pid, token and time named.
  my $race = sub {
    my ( $holder, $waiter, $s ) = @_;
    restore_machine( $m, $saved );
    my $h = start_cli( $CLI{$holder}, $m, { argv => ['sync'], env => { GIT_CONFIG_GLOBAL => "\${TMP}/gitconfig-slow-$s" } } );
    wait_for( sub { -s $owner && eval { js_parse( path($owner)->slurp_utf8 ); 1 } }, 10_000 )
      or return { failed => "the $holder holder never took the lock" };
    my $held = path($owner)->slurp_raw;
    my @w = map { start_cli( $CLI{$waiter}, $m, $_ ) }
      { argv => ['sync'] },
      { argv => [ 'hook', 'session-start' ], stdin => { session_id => 'lock', cwd => '${TMP}/cwd', source => 'startup' } };
    my ( $sync, $hook ) = map { finish_cli($_) } @w;
    my $still = -f $owner && path($owner)->slurp_raw eq $held;
    my $hr = finish_cli($h);
    ( my $named = $held ) =~ s/"pid":(\d+)/$1 == $h->{pid} ? '"pid":"<holder>"' : $&/e;
    $named =~ s/"token":"[0-9a-f]{16}"/"token":"<token>"/;
    $named =~ s/"at":(\d+)/$1 >= $h->{t0} && $1 <= $hr->{t1} ? '"at":"<holder>"' : $&/e;
    return {
      holder => { result => $hr },
      sync   => { result => $sync },
      hook   => { result => $hook },
      owner  => $named,
      still  => $still,
      snap   => snapshot( $m, [ [ $hook->{t0}, $hook->{t1} // 0, 'the waiting SessionStart' ] ] ),
    };
  };

  for my $case ( [ 'waits', 2 ], [ 'times out', 8 ] ) {
    my ( $how, $s ) = @$case;
    subtest "the other $how" => sub {
      my %r = ( ts => $race->( ts => perl => $s ), perl => $race->( perl => ts => $s ) );
      # Keyed by the side compared: the reference's holder and its waiter against the port's.
      my ( $ts_holds, $perl_holds ) = @r{qw( ts perl )};
      for my $run ( $ts_holds, $perl_holds ) { return fail( $run->{failed} ) if $run->{failed} }
      is( $perl_holds->{owner}, $ts_holds->{owner}, 'the same owner record, pid, token and time named' );
      is( $ts_holds->{owner}, qq({"pid":"<holder>","host":"$HOST","token":"<token>","at":"<holder>","refreshMs":10000}),
        'the reference\'s record: pid, host, token, time, refresh' );
      # The holders against each other, the waiters against each other: the reference's first.
      for my $part (qw( holder sync hook )) {
        my ( $want, $got ) = $part eq 'holder'
          ? ( $ts_holds->{$part}{result}, $perl_holds->{$part}{result} )
          : ( $perl_holds->{$part}{result}, $ts_holds->{$part}{result} );
        my $who = $part eq 'holder' ? 'the holder\'s sync' : $part eq 'sync' ? 'the waiting sync' : 'the waiting SessionStart';
        next if grep { defined $_->{failed} and fail("$who: $_->{failed}") } $want, $got;
        is( $got->{exit},   $want->{exit},   "$who: the exit code" );
        is( $got->{stdout}, $want->{stdout}, "$who: stdout" );
        is( $got->{stderr}, $want->{stderr}, "$who: stderr" );
      }
      same_snapshot( 'the machine after', $ts_holds->{snap}, $perl_holds->{snap} );

      # What the reference says, in both races: so the scenario held what it claims.
      for my $who ( [ 'the reference waits', $perl_holds ], [ 'the port waits', $ts_holds ] ) {
        my ( $name, $run ) = @$who;
        my ( $sync, $hold ) = ( $run->{sync}{result}, $run->{holder}{result} );
        is( $hold->{exit}, 0, "$name: the holder synced" );
        if ( $s < 5 ) {
          is( $sync->{stdout}, "skilletor: up to date\n", "$name: its sync found the holder's done" );
          cmp_ok( $sync->{t1} - $sync->{t0}, '>=', 1000, "$name: after waiting for it" );
        }
        else {
          ok( $run->{still}, "$name: both gave up while the holder held the lock" );
          is( $sync->{exit},   1,  "$name: the sync fails" );
          is( $sync->{stdout}, '', "$name: says nothing on stdout" );
          is( $sync->{stderr}, "skilletor: timed out acquiring sync lock at $state/sync.lock\n", "$name: and why on stderr" );
          cmp_ok( $sync->{t1} - $sync->{t0}, '>=', 5000, "$name: after 5 s" );
          is( $run->{hook}{result}{stdout}, qq({"systemMessage":"skilletor: timed out acquiring sync lock at $state/sync.lock"}\n),
            "$name: SessionStart says the same" );
          is( $run->{hook}{result}{exit}, 0, "$name: and exits 0" );
        }
      }
    };
  }
};

#### A stopped holder (k251) ############################################

subtest 'k251: a CLI stopped while it holds the lock: SIGTERM releases it, after a SIGKILL the other CLI breaks it' => sub {
  my $m = machine();
  my $tmp = $m->{tmp};
  BAIL_OUT("a temp path ext:: cannot carry: $tmp") if $tmp =~ /[\s%;"\\]/;
  make_repo( "$tmp/git/slow", 'skills/lint/SKILL.md' => skill('lint') );
  my $url = 'https://parity.invalid/slow.git';
  gitconfig( $m, 'gitconfig', { $url => "file://$tmp/git/slow" } );
  gitconfig( $m, 'gitconfig-slow', { $url => "ext::sh -c sleep% 60;exec% git-upload-pack% $tmp/git/slow" },
    qq([protocol "ext"]\n\tallow = always\n) );
  write_json( "$m->{home}/.claude/skilletor.json", { sources => { slow => { git => $url } }, install => { skills => ['lint@slow'] } } );
  my $saved = save_machine($m);
  my $state = "$m->{home}/.claude/skilletor";
  my $owner = "$state/sync.lock/owner.json";
  my $leftovers = sub { [ grep { /\Async\.lock\./ } map { $_->basename } path($state)->children ] };

  # A CLI in a process group of its own, its fetch asleep: once it holds the lock, $signal goes to
  # the group, as Claude Code cancels a hook. Its result and the pid it held the lock with.
  my $stop = sub {
    my ( $cli, $step, $signal ) = @_;
    restore_machine( $m, $saved );
    my $run = start_cli( $CLI{$cli}, $m, { %$step, group => 1, env => { GIT_CONFIG_GLOBAL => '${TMP}/gitconfig-slow' } } );
    my $held = wait_for( sub { -s $owner && ( eval { js_parse( path($owner)->slurp_utf8 )->{pid} } // 0 ) == $run->{pid} }, 15_000 );
    kill $signal, -$run->{pid};
    return ( finish_cli( $run, 10_000 ), $held, $run->{pid} );
  };

  for my $cli (qw( ts perl )) {
    my $other = $cli eq 'ts' ? 'perl' : 'ts';
    subtest "the $cli CLI holds it" => sub {
      # The reported case: a SessionStart cancelled while its sync holds the lock.
      my $input = { session_id => 'k251', cwd => '${TMP}/cwd', source => 'startup' };
      my ( $r, $held ) = $stop->( $cli, { argv => [ 'hook', 'session-start' ], stdin => $input }, 'TERM' );
      ok( $held, 'its SessionStart took the lock' );
      like( $r->{failed} // '', qr/ was killed by signal 15\z/, 'it ended by SIGTERM, as without the lock' );
      is( $r->{stdout}, '', 'and said nothing' );
      ok( !-e "$state/sync.lock", 'the lock released' );
      is_deeply( $leftovers->(), [], 'nothing left beside it' );

      # The contract for a stop no process can catch: the lock left, of this host and a pid that is
      # gone; once its record missed two refreshes (20 s at the default 10 s, here aged so), the
      # other CLI's sync breaks it at once and syncs.
      ( $r, $held, my $pid ) = $stop->( $cli, { argv => ['sync'] }, 'KILL' );
      ok( $held, 'its sync took the lock' );
      like( $r->{failed} // '', qr/ was killed by signal 9\z/, 'killed' );
      my $record = eval { js_parse( path($owner)->slurp_utf8 ) } // {};
      is_deeply( [ @{$record}{qw( pid host )} ], [ $pid, $HOST ], 'the lock left, a dead owner of this host' );
      my $then = time - 21;
      utime $then, $then, $owner;
      my $next = run_cli( $CLI{$other}, $m, { argv => ['sync'] } );
      is( $next->{exit}, 0, "the $other CLI synced" ) or diag $next->{failed} // $next->{stderr};
      like( $next->{stdout} // '', qr{skills/lint}, 'the skill installed' );
      ok( !-e "$state/sync.lock", 'no lock left' );
      is( scalar( grep { /\Async\.lock\.broken-/ } @{ $leftovers->() } ), 1, 'the dead one broken, one tombstone' );
    };
  }
};

done_testing;
