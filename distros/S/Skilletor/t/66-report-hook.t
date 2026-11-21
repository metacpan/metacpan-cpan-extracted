#!/usr/bin/env perl
# The hooks' output of a sync report (k180): Skilletor::Report::report_hook is the reference's
# reportHook (report.ts), withoutRepeats with it – a one-line systemMessage and a terse
# additionalContext, every line display-safe, a config error alone as one line; the briefing and
# settings warnings shown only by a run that changed something. The inputs of report.test.ts are
# pinned here as that file pins them, more beside them; with node, the reference's answer to each
# input must be the same bytes.
use strict;
use warnings;
use utf8;
use Test::More;
use FindBin;

use IPC::Open2 qw( open2 );
use JSON::MaybeXS ();
use Path::Tiny qw( path );
use Skilletor::Briefing qw( briefing_warning );
use Skilletor::FSUtil qw( decode_utf8_lossy encode_text );
use Skilletor::JSON qw( js_ordered js_parse js_stringify );
use Skilletor::Report qw( conflict_hint empty_scope_report report_hook );

# A scope report as the reference's tests build one: emptyScopeReport, then each field assigned in
# turn – an existing key keeps its place, a new one comes last.
sub scope {
  my ( $name, @fields ) = @_;
  my $s = empty_scope_report($name);
  while (@fields) {
    my ( $k, $v ) = splice @fields, 0, 2;
    $s->{$k} = $v;
  }
  return $s;
}

sub item { js_ordered( key => $_[0], type => $_[1], name => $_[2], source => $_[3] ) }
sub trust_request { js_ordered( name => $_[0], kind => $_[1], url => $_[2] ) }
sub report { js_ordered( scopes => [@_] ) }

sub sample {
  return report( scope( 'user',
    added         => [ item( 'skills/foo', 'skill', 'foo', 'shared' ) ],
    updated       => [ item( 'agents/bar', 'agent', 'bar', 'shared' ) ],
    warnings      => ['source team offline'],
    trustRequests => [ trust_request( 'team', 'local', '/src/team' ) ],
  ) );
}

# An ANSI colour escape, a BEL, a right-to-left override and a newline, and how each shows.
my $EVIL  = "\x{1b}[31mred\x{07}\x{202e}evil\nnext";
my $SHOWN = '\\u001b[31mred\\u0007\\u202eevil\\nnext';

my $brief      = briefing_warning( 'rev', 'claude', [ 'gone', 'gone2' ] );
my $brief_cx   = briefing_warning( 'rev', 'codex', ['pa'] );
my $missing    = js_ordered( key => 'agents/rev', harness => 'claude', missing => [ 'gone', 'gone2' ] );
my $missing_cx = js_ordered( key => 'codex:agents/rev', harness => 'codex', missing => ['pa'] );
my $settings   = js_ordered( path => '.claude/settings.json', enabled => ['skilletor@getty'], declared => [ 'getty', 'other' ] );
my $skipped_w  = 'marketplace getty: its source is a local directory, never written to the committed file';

my @cases = (
  # ---- the inputs of report.test.ts ----------------------------------------------------------
  [ 'an empty report is not notable' => report( scope('user') ), {} ],
  [ 'items, a warning and a trust request' => sample(), {
      systemMessage     => 'skilletor: 2 item(s) updated, 2 warning(s)',
      additionalContext => join( "\n",
        'skilletor synced items:',
        '- skill foo@shared: active now',
        '- agent bar@shared: active after /reload-plugins or restart',
        '- untrusted source team (local /src/team); run: skilletor trust team',
        '- warning: source team offline' ),
  } ],
  [ 'k86: a config error is one line' => js_ordered( scopes => [], error => '/p/.claude/skilletor.json: invalid JSON (x)' ),
    { systemMessage => 'skilletor: /p/.claude/skilletor.json: invalid JSON (x)' } ],
  [ 'k86: an error wins over scope contents' => do { my $r = sample(); $r->{error} = 'invalid JSON'; $r },
    { systemMessage => 'skilletor: invalid JSON' } ],
  [ 'skipped items make no hook report' => report( scope( 'project', skipped => [ item( 'rules/k8s', 'rule', 'k8s', 'shared' ) ] ) ), {} ],
  [ 'a changed .gitignore block asks for a commit' => report( scope( 'project', gitignoreUpdated => ['.claude/.gitignore'] ) ), {
      systemMessage     => 'skilletor: .claude/.gitignore updated — commit it',
      additionalContext => '- .claude/.gitignore updated — commit it',
  } ],
  [ 'two of them: commit them' =>
      report( scope( 'user', gitignoreUpdated => ['~/.claude/.gitignore'] ), scope( 'project', gitignoreUpdated => ['.claude/.gitignore'] ) ), {
      systemMessage     => 'skilletor: ~/.claude/.gitignore, .claude/.gitignore updated — commit them',
      additionalContext => "- ~/.claude/.gitignore updated — commit it\n- .claude/.gitignore updated — commit it",
  } ],
  [ 'k72: every conflict with its scope, path and hint' => report(
      scope( 'user', conflicts => [ js_ordered( path => 'skills/x/SKILL.md', notFile => JSON::MaybeXS::true() ), js_ordered( path => 'agents/a.md', replace => JSON::MaybeXS::true() ) ] ),
      scope( 'project', conflicts => [ js_ordered( path => 'skills/y/SKILL.md' ) ] ),
    ), {
      systemMessage     => 'skilletor: 3 warning(s)',
      additionalContext => join( "\n",
        '- conflict in user scope: skills/x/SKILL.md '.conflict_hint( { notFile => 1 } ),
        '- conflict in user scope: agents/a.md '.conflict_hint( { replace => 1 } ),
        '- conflict in project scope: skills/y/SKILL.md '.conflict_hint( {} ) ),
  } ],
  [ 'k72: every overwritten local change with its scope' =>
      report( scope( 'project', overwritten => [ js_ordered( path => 'skills/x/SKILL.md' ), js_ordered( path => '.codex/skilletor-rules.md#rules/k8s' ) ] ) ), {
      systemMessage     => 'skilletor: 2 warning(s)',
      additionalContext => "- overwrote local change in project scope: skills/x/SKILL.md\n- overwrote local change in project scope: .codex/skilletor-rules.md#rules/k8s",
  } ],
  [ 'k72: one context line per counted warning' => report( scope( 'user',
      warnings      => ['source team offline'],
      conflicts     => [ js_ordered( path => 'skills/y/SKILL.md' ) ],
      trustRequests => [ trust_request( 'team', 'local', '/src/team' ) ],
      overwritten   => [ js_ordered( path => 'skills/x/SKILL.md' ) ],
    ) ), {
      systemMessage     => 'skilletor: 4 warning(s)',
      additionalContext => join( "\n",
        '- overwrote local change in user scope: skills/x/SKILL.md',
        '- conflict in user scope: skills/y/SKILL.md already exists (use --force to adopt)',
        '- untrusted source team (local /src/team); run: skilletor trust team',
        '- warning: source team offline' ),
  } ],
  [ 'k87: config-, source- and git-derived strings escaped' => report( scope( 'project',
      added         => [ item( 'skills/foo', 'skill', 'foo', "team$EVIL" ) ],
      overwritten   => [ js_ordered( path => "skills/foo/$EVIL.md" ) ],
      trustRequests => [ trust_request( "team$EVIL", 'local', "/src/$EVIL" ) ],
      warnings      => ["git fetch failed: $EVIL"],
    ) ), {
      systemMessage     => 'skilletor: 1 item(s) updated, 3 warning(s)',
      additionalContext => join( "\n",
        'skilletor synced items:',
        "- skill foo\@team$SHOWN: active now",
        "- overwrote local change in project scope: skills/foo/$SHOWN.md",
        "- untrusted source team$SHOWN (local /src/$SHOWN); run: skilletor trust team$SHOWN",
        "- warning: git fetch failed: $SHOWN" ),
  } ],
  [ 'k87: an escaped config error' => js_ordered( scopes => [], error => "sources.team$EVIL: unknown key" ),
    { systemMessage => "skilletor: sources.team$SHOWN: unknown key" } ],

  # ---- more: withoutRepeats ------------------------------------------------------------------
  [ 'a briefing warning of a run that changed nothing is not repeated' =>
      report( scope( 'user', warnings => [$brief], briefingMissing => [$missing] ) ), {} ],
  [ 'only the briefing line goes; the other warnings stay' =>
      report( scope( 'user', warnings => [ 'source a offline', $brief, 'source b offline' ], briefingMissing => [$missing] ) ), {
      systemMessage     => 'skilletor: 2 warning(s)',
      additionalContext => "- warning: source a offline\n- warning: source b offline",
  } ],
  [ 'a run that changed something shows the briefing warning' =>
      report( scope( 'user', added => [ item( 'skills/foo', 'skill', 'foo', 's' ) ], warnings => [$brief], briefingMissing => [$missing] ) ), {
      systemMessage     => 'skilletor: 1 item(s) updated, 1 warning(s)',
      additionalContext => "skilletor synced items:\n- skill foo\@s: active now\n- warning: $brief",
  } ],
  [ "a change in another scope counts: hasChanges is the run's" => report(
      scope( 'user', warnings => [$brief], briefingMissing => [$missing] ),
      scope( 'project', removed => [ item( 'rules/old', 'rule', 'old', 's' ) ] ),
    ), {
      systemMessage     => 'skilletor: 1 removed, 1 warning(s)',
      additionalContext => "- warning: $brief",
  } ],
  [ 'every copy of a repeated line goes, a Codex agent named with its harness' =>
      report( scope( 'user', warnings => [ $brief_cx, 'kept', $brief_cx ], briefingMissing => [$missing_cx] ) ), {
      systemMessage     => 'skilletor: 1 warning(s)',
      additionalContext => '- warning: kept',
  } ],
  [ 'settings warnings of a scope whose settings file stayed as it was are not repeated' =>
      report( scope( 'project', warnings => [$skipped_w], settingsSkipped => [$skipped_w] ) ), {} ],
  [ 'settings warnings of a run that updated the settings file stay' =>
      report( scope( 'project', warnings => [$skipped_w], settingsUpdated => $settings, settingsSkipped => [$skipped_w] ) ), {
      systemMessage     => 'skilletor: 1 warning(s), .claude/settings.json updated — commit it',
      additionalContext => "- .claude/settings.json updated (enables skilletor\@getty; declares marketplaces getty, other) — commit it\n- warning: $skipped_w",
  } ],
  [ 'empty briefingMissing and settingsSkipped leave the scope as it is' =>
      report( scope( 'user', warnings => ['w'], briefingMissing => [], settingsSkipped => [] ) ),
    { systemMessage => 'skilletor: 1 warning(s)', additionalContext => '- warning: w' } ],

  # ---- more: the counts, the marks, the hints ------------------------------------------------
  [ 'removed only: a line, no context' => report( scope( 'user', removed => [ item( 'skills/old', 'skill', 'old', 's' ) ] ) ),
    { systemMessage => 'skilletor: 1 removed' } ],
  [ 'items of other harnesses carry their harness and hint' => report( scope( 'user',
      added   => [ item( 'codex:skills/a', 'skill', 'a', 's' ), item( 'hermes:skills/b', 'skill', 'b', 's' ), item( 'agents/c', 'agent', 'c', 's' ) ],
      updated => [ item( 'other:rules/d', 'rule', 'd', 's' ) ],
    ) ), {
      systemMessage     => 'skilletor: 4 item(s) updated',
      additionalContext => join( "\n",
        'skilletor synced items:',
        '- skill a@s (codex): active from the next Codex session',
        '- skill b@s (hermes): active from the next Hermes session',
        '- agent c@s: active after /reload-plugins or restart',
        '- rule d@s: active after /reload-plugins or restart' ),
  } ],
  [ 'the settings file alone' => report( scope( 'project', settingsUpdated => $settings ) ), {
      systemMessage     => 'skilletor: .claude/settings.json updated — commit it',
      additionalContext => '- .claude/settings.json updated (enables skilletor@getty; declares marketplaces getty, other) — commit it',
  } ],
  [ 'a .gitignore and the settings file: commit them' => report( scope( 'project',
      gitignoreUpdated => [ '.claude/.gitignore', '.worktreeinclude' ],
      settingsUpdated  => js_ordered( path => '.claude/settings.json', enabled => [], declared => ['getty'] ),
    ) ), {
      systemMessage     => 'skilletor: .claude/.gitignore, .worktreeinclude, .claude/settings.json updated — commit them',
      additionalContext => join( "\n",
        '- .claude/.gitignore updated — commit it',
        '- .worktreeinclude updated — commit it',
        '- .claude/settings.json updated (declares marketplace getty) — commit it' ),
  } ],
  [ 'unchanged items say nothing' => report( scope( 'user', unchanged => [ item( 'skills/foo', 'skill', 'foo', 's' ) ] ) ), {} ],
  [ "the run's own warnings and notes are not the hooks'" =>
      js_ordered( scopes => [ scope('user') ], warnings => ['codex hook untrusted'], notes => ['1 agent(s) not installed for Hermes'] ), {} ],
  [ 'an empty error is no error' => do { my $r = sample(); $r->{error} = ''; $r }, {
      systemMessage     => 'skilletor: 2 item(s) updated, 2 warning(s)',
      additionalContext => join( "\n",
        'skilletor synced items:',
        '- skill foo@shared: active now',
        '- agent bar@shared: active after /reload-plugins or restart',
        '- untrusted source team (local /src/team); run: skilletor trust team',
        '- warning: source team offline' ),
  } ],
  [ 'an empty error alone says nothing' => js_ordered( scopes => [ scope('user') ], error => '' ), {} ],
);

for my $c (@cases) {
  my ( $name, $report, $want ) = @$c;
  my $before = js_stringify($report);
  my $got = report_hook($report);
  is_deeply( { %$got }, $want, $name );
  is_deeply( [ keys %$got ], [ grep { exists $want->{$_} } qw( systemMessage additionalContext ) ], "$name: systemMessage first" );
  is( js_stringify($report), $before, "$name: the report is left as it was" );
}

# The reference's answer, byte for byte.
my $runner = path( $FindBin::Bin, '..', 'maint', 'ts-run.mjs' );
my $src_ts = path( $FindBin::Bin, '..', 'src', 'report.ts' );
my $why_not =
    !$runner->exists || !$src_ts->exists                                   ? 'needs the skilletor checkout (src/) and maint/ts-run.mjs'
  : !grep( { -x path( $_, 'node' ) } split /:/, $ENV{PATH} // '' )         ? 'needs node'
  : !path( $FindBin::Bin, '..', 'node_modules', 'nunjucks' )->exists ? "needs the reference's node_modules"
  :                                                                          undef;

SKIP: {
  skip $why_not, scalar @cases if defined $why_not;
  my $pid = open2( my $out, my $in, 'node', "$runner" );
  binmode $in, ':raw';
  print {$in} encode_text( js_stringify( js_ordered( op => 'reportHook', reports => [ map { $_->[1] } @cases ] ) ) );
  close $in;
  my $text = do { local $/; <$out> };
  waitpid $pid, 0;
  my $answer = js_parse( decode_utf8_lossy( $text // '' ) );
  die 'ts-run: '.( $answer->{error} // $text ) unless ref $answer->{result} eq 'ARRAY';
  for my $i ( 0 .. $#cases ) {
    is( js_stringify( report_hook( $cases[$i][1] ) ), js_stringify( $answer->{result}[$i] ), "the reference: $cases[$i][0]" );
  }
}

done_testing;
