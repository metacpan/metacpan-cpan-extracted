package Skilletor::Hooks;
# ABSTRACT: The session hooks – SessionStart, UserPromptSubmit, the background sync and the checkout moves (spec §8)

use strict;
use warnings;
use utf8;

use Cwd ();
use Exporter qw( import );
use Scalar::Util qw( blessed );
use Time::HiRes ();
use Skilletor::FSUtil qw( decode_utf8_lossy encode_text node_fs_error path_join path_resolve same_path );
use Skilletor::GitEnv qw( git_env );
use Skilletor::JSON qw( js_ordered js_type );
use Skilletor::Process qw( run_command spawn_detached );

our $VERSION = '0.008000';

our @EXPORT_OK = qw( run_hook project_root_of default_background SESSION_START_TIMEOUT_MS DEFAULT_INTERVAL MOVE_DEADLINE_MS );

# A SessionStart check and sync give each source this long (the reference's 5 s).
use constant SESSION_START_TIMEOUT_MS => 5_000;

# The in-session check's interval when the config cannot be loaded; the config's own default
# (checkInterval, 1800 s) is Skilletor::Config's.
use constant DEFAULT_INTERVAL => 600;

# SessionStart or a move's sync writes nothing once this has passed (spec §8): Claude Code kills
# the hook at 30 s, which leaves the local rest of a sync 10 s. The two move hooks wait for the
# sync lock up to it as well. The exported name predates SessionStart's use of the same budget.
use constant MOVE_DEADLINE_MS => 20_000;

# State, Config and Engine are loaded by the events that use them: a prompt with nothing due
# loads no engine. The report module is loaded by the first answer that says something (k199).
sub display_safe       { require Skilletor::Report; goto &Skilletor::Report::display_safe }
sub empty_scope_report { require Skilletor::Report; goto &Skilletor::Report::empty_scope_report }
sub report_hook        { require Skilletor::Report; goto &Skilletor::Report::report_hook }

# The project of a directory, as the hooks and the CLI find it (spec §14.5): git's top level of
# $cwd – of the repository found from $cwd, never one an exported GIT_DIR names (k91) – else $cwd
# itself. The reference's projectRootOf: one git run, 2 s, git's environment. Never dies.
sub project_root_of {
  my ( $cwd ) = @_;
  my $r = eval {
    run_command( cmd => [ 'git', '-C', encode_text($cwd), 'rev-parse', '--show-toplevel' ], env => git_env(), timeout_ms => 2_000 );
  };
  return $cwd unless $r && !$r->{spawn_error} && !$r->{timed_out} && defined $r->{code} && $r->{code} == 0;
  ( my $top = decode_utf8_lossy( $r->{stdout} ) ) =~ s/\A\s+|\s+\z//g;
  return length $top ? path_resolve($top) : $cwd;
}

# A string's truthiness in JavaScript: set and not empty.
sub _truthy { defined $_[0] && length $_[0] }

# A hook input's string field, when it is a non-empty one.
sub _text { js_type( $_[0] ) eq 'string' && length $_[0] ? $_[0] : undef }

# The session a hook input belongs to; '' when it names none.
sub _session_of { js_type( $_[0]{session_id} ) eq 'string' ? $_[0]{session_id} : '' }

sub _project_key {
  my ( $ctx, $input ) = @_;
  return $ctx->{project_dir} // _text( $input->{cwd} ) // '';
}

# The project dir, unless it is the home dir itself: then there is no project scope.
sub _project_dir_of {
  my ( $ctx ) = @_;
  my $p = $ctx->{project_dir};
  return undef if !_truthy($p) || same_path( $p, $ctx->{home} );
  return $p;
}

# Claude Code's config dir as the hook's context gives it, else CLAUDE_CONFIG_DIR.
sub _claude_config_dir {
  my ( $ctx ) = @_;
  return $ctx->{claude_config_dir} if _truthy( $ctx->{claude_config_dir} );
  return _truthy( $ENV{CLAUDE_CONFIG_DIR} ) ? decode_utf8_lossy( $ENV{CLAUDE_CONFIG_DIR} ) : undef;
}

# What a caught error says: a Skilletor::Error's message, else Perl's text without the
# " at FILE line N." it appends.
sub _message {
  my ( $err ) = @_;
  return $err->message if blessed $err && $err->can('message');
  my $text = "$err";
  $text =~ s/ at (?:(?! at ).)+ line \d+(?:, <[^>]*> (?:line|chunk) \d+)?\.\n\z//s;
  chomp $text;
  return $text;
}

sub _lock_timeout { blessed $_[0] && $_[0]->isa('Skilletor::Error::LockTimeout') }

# One warning line; the message – an error, git's stderr, a name from a config – display-safe.
sub _warn { js_ordered( systemMessage => display_safe( 'skilletor: '.$_[0] ) ) }

# A sync report as hook output: the line and, under the event's name, the context.
sub _to_output {
  my ( $report, $event ) = @_;
  my $h = report_hook($report);
  return js_ordered() unless _truthy( $h->{systemMessage} ) || _truthy( $h->{additionalContext} );
  return js_ordered(
    ( defined $h->{systemMessage} ? ( systemMessage => $h->{systemMessage} ) : () ),
    hookSpecificOutput =>
      js_ordered( hookEventName => $event, ( defined $h->{additionalContext} ? ( additionalContext => $h->{additionalContext} ) : () ) ),
  );
}

sub _state {
  my ( $ctx ) = @_;
  require Skilletor::State;
  return Skilletor::State->new( root => $ctx->{state_root} );
}

# The engine for the hook's project; %defaults (a per-source timeout) yield to the context's own
# engine arguments.
sub _engine {
  my ( $ctx, %defaults ) = @_;
  require Skilletor::Engine;
  return Skilletor::Engine->new(
    %defaults,
    home              => $ctx->{home},
    project_dir       => $ctx->{project_dir},
    claude_config_dir => _claude_config_dir($ctx),
    state_root        => $ctx->{state_root},
    %{ $ctx->{engine} // {} },
  );
}

sub _cwd {
  my $cwd = Cwd::getcwd();
  die "ENOENT: process.cwd failed with error no such file or directory, uv_cwd\n" unless defined $cwd;
  return decode_utf8_lossy($cwd);
}

sub run_hook {
  my ( $event, $input, $hook_ctx ) = @_;
  my $out;
  return $out if eval { $out = _dispatch( $event, $input, $hook_ctx ); 1 };
  return _warn( _message($@) );
}

sub _dispatch {
  my ( $event, $input, $hook_ctx ) = @_;
  # The checkout the session moved into is the project, never the session's own (spec §8).
  return _cwd_changed( $input, $hook_ctx )   if $event eq 'cwd-changed';
  return _post_tool_use( $input, $hook_ctx ) if $event eq 'post-tool-use';
  my $ctx = _truthy( $hook_ctx->{project_dir} ) ? $hook_ctx : { %$hook_ctx, project_dir => project_root_of( _text( $input->{cwd} ) // _cwd() ) };
  return _session_start( $input, $ctx )      if $event eq 'session-start';
  return _user_prompt_submit( $input, $ctx ) if $event eq 'user-prompt-submit';
  if ( $event eq '__sync-background' ) {
    _sync_background( $input, $ctx );
    return js_ordered();
  }
  return _warn("unknown hook event: $event");
}

# Under Codex a new session (no source, `startup` or `clear`) gets the rules context; a resumed
# one still has the first copy in its history (spec §14.8). Under Hermes, while `hermes` is no
# target, the answer says how to opt in (spec §16.2).
sub _session_start {
  my ( $input, $ctx ) = @_;
  my $out;
  $out = _warn( _message($@) ) unless eval { $out = _check_and_sync( $input, $ctx ); 1 };
  _record_session_cwd( $input, $ctx );
  my $source = $input->{source};
  if ( ( $ctx->{harness} // '' ) eq 'codex'
    && ( !defined $source || ( js_type($source) eq 'string' && ( $source eq 'startup' || $source eq 'clear' ) ) ) ) {
    $out = _with_codex_rules( $out, $ctx );
  }
  $out = _with_hermes_opt_in( $out, $ctx ) if ( $ctx->{harness} // '' ) eq 'hermes';
  return $out;
}

# Under Hermes while `hermes` is no target (spec §16.2): the opt-in line, once per answer – after
# its warning line, and after its context when it has one, since the plugin hands the model the
# context and the warning line only without one (spec §16.4).
sub _with_hermes_opt_in {
  my ( $out, $ctx ) = @_;
  my $hint = _engine($ctx)->hermes_opt_in_hint;
  return $out unless _truthy($hint);
  my $line   = _warn($hint)->{systemMessage};
  my $result = js_ordered( map { ( $_ => $out->{$_} ) } keys %$out );
  $result->{systemMessage} = join '; ', grep { _truthy($_) } $out->{systemMessage}, $line;
  my $hso     = $out->{hookSpecificOutput};
  my $context = ref $hso eq 'HASH' ? $hso->{additionalContext} : undef;
  if ( _truthy($context) ) {
    my $copy = js_ordered( map { ( $_ => $hso->{$_} ) } keys %$hso );
    $copy->{additionalContext} = "$context\n$line";
    $result->{hookSpecificOutput} = $copy;
  }
  return $result;
}

# The Codex rules files, read from disk, at the start of the output's additionalContext, so the
# message begins with the rules marker the pointer names; a file that cannot be read is one more
# warning.
sub _with_codex_rules {
  my ( $out, $ctx ) = @_;
  my ( @texts, @problems );
  for my $file ( _engine($ctx)->codex_rules_files ) {
    my $text = _read_rules($file);
    if   ( ref $text ) { push @problems, "cannot read $file ($$text)" }
    else               { push @texts, $text }
  }
  my $result = js_ordered( map { ( $_ => $out->{$_} ) } keys %$out );
  $result->{systemMessage} = join '; ', grep { _truthy($_) } $out->{systemMessage}, _warn( join '; ', @problems )->{systemMessage} if @problems;
  if (@texts) {
    my $rules  = join "\n", @texts;
    my $report = ( $out->{hookSpecificOutput} // {} )->{additionalContext};
    $result->{hookSpecificOutput} = js_ordered( hookEventName => 'SessionStart', additionalContext => _truthy($report) ? "$rules\n$report" : $rules );
  }
  return $result;
}

# A file's text as readFileSync(file, "utf8") gives it, or a reference to Node's message.
sub _read_rules {
  my ( $file ) = @_;
  open( my $fh, '<:raw', encode_text($file) ) or return \node_fs_error( 0 + $!, 'open', $file );
  my $raw = do { local $/; <$fh> };
  return \node_fs_error( 0 + $!, 'read' ) unless defined $raw;
  return decode_utf8_lossy($raw);
}

sub _check_and_sync {
  my ( $input, $ctx ) = @_;
  # The check, sync-lock wait and source resolution all precede the engine's first-write guard,
  # so SessionStart's write budget starts before the check. An earlier caller deadline stays so.
  my $budget_deadline = _now_ms() + MOVE_DEADLINE_MS;
  my $deadline = defined $ctx->{deadline} && $ctx->{deadline} < $budget_deadline ? $ctx->{deadline} : $budget_deadline;
  my $state = _state($ctx);
  my $key = _project_key( $ctx, $input );
  my $engine = _engine( $ctx, timeout_ms => SESSION_START_TIMEOUT_MS );

  my $chk = $engine->check;
  return _warn( $chk->{error} ) if _truthy( $chk->{error} );
  $state->mark_checked($key);

  return _unchanged_output($chk) unless $chk->{changed};
  my $report;
  unless ( eval { $report = $engine->sync( deadline => $deadline ); 1 } ) {
    my $err = $@;
    $state->due_again($key) if _lock_timeout($err);
    die $err;
  }
  return _to_output( $report, 'SessionStart' );
}

# A check with nothing to sync: its warnings in one line – or, when a source awaits trust, the
# report a sync would give, trust requests and warnings alike (spec §4.3, §8).
sub _unchanged_output {
  my ( $chk ) = @_;
  unless ( @{ $chk->{trustRequests} // [] } ) {
    return @{ $chk->{warnings} } ? _warn( join '; ', @{ $chk->{warnings} } ) : js_ordered();
  }
  return _to_output( _trust_report($chk), 'SessionStart' );
}

# The report a sync would give of a check whose sources await trust (at least one).
sub _trust_report {
  my ( $chk ) = @_;
  my $report = js_ordered( scopes => [] );
  my %by_scope;
  for my $t ( @{ $chk->{trustRequests} } ) {
    my $rep = $by_scope{ $t->{scope} } //= do {
      my $r = empty_scope_report( $t->{scope} );
      push @{ $report->{scopes} }, $r;
      $r;
    };
    push @{ $rep->{trustRequests} }, js_ordered( map { ( $_ => $t->{$_} ) } grep { $_ ne 'scope' } keys %$t );
  }
  push @{ $report->{scopes}[0]{warnings} }, @{ $chk->{warnings} };
  return $report;
}

# Where a session's SessionStart looked (k149). Best effort: without the record the first move
# looks once more.
sub _record_session_cwd {
  my ( $input, $ctx ) = @_;
  my $cwd = _text( $input->{cwd} ) // return;
  eval { _state($ctx)->put_session_cwd( _session_of($input), $cwd ); 1 };
  return;
}

# ---- checkout moves (spec §8) ----------------------------------------------------------------

sub _now_ms { int( Time::HiRes::time() * 1000 ) }

# A session moved into $move->{cwd} (the reference's moveCheckout): the checkout is the git top
# level of the new cwd, never the session's project. Nothing to do – no source asked, nothing
# written – when it is the old cwd's checkout, the home dir, has no `.claude/skilletor.json`, or
# its lock already matches its config (a local check). Otherwise its project scope syncs as at
# SessionStart – 5 s per source, nothing written once the deadline has passed – unless, once the
# sync lock is held, its lock matches after all: another run synced it meanwhile. One line names
# the checkout and, when something is left to do, the command to run there. Never dies.
#
# $move: cwd, old_cwd (when the event names one), event (the answer's hookEventName),
# lock_until_deadline (wait for the sync lock until the deadline, not the usual 5 s: Claude Code
# fires two move hooks for one `cd`, and the second waits out the other's sync). Returns the
# answer and – when it answered for the checkout, with a sync or with what is left to do there –
# that checkout. Under Hermes, once skills landed, the line also names `hermes skills trust` as
# one that may be needed (k152).
sub _move_checkout {
  my ( $move, $ctx ) = @_;
  my $root = project_root_of( $move->{cwd} );
  my @result;
  return @result if eval { @result = _move_checkout_of( $root, $move, $ctx ); 1 };
  my $err = $@;
  # Timed out on the sync lock: another run holds it – a background sync of this very checkout,
  # maybe – and synced nothing here, so the interval check is left to retry (k89).
  return ( _cannot_sync( $root, _message($err) ), _lock_timeout($err) ? undef : $root );
}

sub _move_checkout_of {
  my ( $root, $move, $ctx ) = @_;
  return js_ordered() if same_path( $root, $ctx->{home} ) || !-e encode_text( path_join( $root, '.claude', 'skilletor.json' ) );
  return js_ordered() if defined $move->{old_cwd} && same_path( project_root_of( $move->{old_cwd} ), $root );
  my $deadline = $ctx->{deadline} // _now_ms() + MOVE_DEADLINE_MS;
  # Past the deadline the sync writes nothing: a longer wait would be for nothing.
  my $lock_timeout = ( $ctx->{engine} // {} )->{lock_timeout_ms};
  if ( !defined $lock_timeout && $move->{lock_until_deadline} ) {
    $lock_timeout = $deadline - _now_ms();
    $lock_timeout = 0 if $lock_timeout < 0;
  }
  my $engine = _engine( { %$ctx, project_dir => $root }, timeout_ms => SESSION_START_TIMEOUT_MS );
  my $chk = $engine->check( scope => 'project', local => 1 );
  return ( _cannot_sync( $root, $chk->{error} ), $root ) if _truthy( $chk->{error} );
  unless ( $chk->{changed} ) {
    return ( _moved_output( _trust_report($chk), $root, $move->{event} ), $root ) if @{ $chk->{trustRequests} // [] };
    return @{ $chk->{warnings} } ? ( _cannot_sync( $root, join '; ', @{ $chk->{warnings} } ), $root ) : js_ordered();
  }
  # No scopes: a run this one waited for on the sync lock – the other Claude Code hook of the
  # same `cd`, say – synced the checkout meanwhile, and its answer was that run's to give.
  my $report = $engine->sync( scope => 'project', if_changed => 1, deadline => $deadline, lock_timeout_ms => $lock_timeout );
  return js_ordered() if !_truthy( $report->{error} ) && !@{ $report->{scopes} };
  return ( _cannot_sync( $root, $report->{error} ), $root ) if _truthy( $report->{error} );
  my $out = _moved_output( $report, $root, $move->{event} );
  $out = _with_hermes_trust( $out, $root ) if ( $ctx->{harness} // '' ) eq 'hermes' && grep { _adds_hermes_skill($_) } @{ $report->{scopes} };
  return ( $out, $root );
}

# Did a scope's sync add or update a skill Hermes loads from the project – its own copy, or the
# Codex copy in `.agents/skills` it reads instead (spec §16.2)?
sub _adds_hermes_skill {
  my ( $s ) = @_;
  require Skilletor::Lock;
  for my $it ( @{ $s->{added} // [] }, @{ $s->{updated} // [] } ) {
    my $k = Skilletor::Lock::parse_lock_key( $it->{key} );
    return 1 if $k->{type} eq 'skill' && defined $k->{harness} && ( $k->{harness} eq 'hermes' || $k->{harness} eq 'codex' );
  }
  return 0;
}

# A Hermes move that put skills into a checkout (k152): Hermes loads a project's skills only once
# `hermes skills trust` named its root, and skilletor does not read that list (spec §16.5) – so
# the line and the context name the command as one that may be needed, the context as the user's
# to run.
sub _with_hermes_trust {
  my ( $out, $dir ) = @_;
  my $command = "hermes skills trust $dir";
  my $result  = js_ordered( map { ( $_ => $out->{$_} ) } keys %$out );
  $result->{systemMessage} = display_safe( ( $out->{systemMessage} // 'undefined' )." — if Hermes does not trust this project yet: $command" );
  my $hso     = $out->{hookSpecificOutput};
  my $context = ref $hso eq 'HASH' ? $hso->{additionalContext} : undef;
  if ( _truthy($context) ) {
    my $line = "- Hermes loads project skills only from a project it trusts; if this one is not yet, the user can run: $command";
    my $copy = js_ordered( map { ( $_ => $hso->{$_} ) } keys %$hso );
    $copy->{additionalContext} = "$context\n".display_safe($line);
    $result->{hookSpecificOutput} = $copy;
  }
  return $result;
}

# The one line of a move that could not sync: the checkout, why, and what to run there.
sub _cannot_sync {
  my ( $dir, $message ) = @_;
  return _warn("cannot sync $dir: $message — run there: skilletor sync");
}

# A move's report: the line says where, and what to run there for what is left – trusting a
# source, or a sync that shows each warning and conflict; the context says where first.
sub _moved_output {
  my ( $report, $dir, $event ) = @_;
  my $out = _to_output( $report, $event );
  return $out unless _truthy( $out->{systemMessage} );
  my ( @fixes, %seen );
  for my $s ( @{ $report->{scopes} } ) {
    push @fixes, grep { !$seen{$_}++ } map { "skilletor trust $_->{name}" } @{ $s->{trustRequests} // [] };
  }
  push @fixes, 'skilletor sync' if grep { @{ $_->{warnings} // [] } || @{ $_->{conflicts} // [] } } @{ $report->{scopes} };
  my $result = js_ordered( systemMessage => display_safe( "$out->{systemMessage} in $dir".( @fixes ? ' — run there: '.join( '; ', @fixes ) : '' ) ) );
  my $context = ( $out->{hookSpecificOutput} // {} )->{additionalContext};
  if ( _truthy($context) ) {
    $result->{hookSpecificOutput} = js_ordered( hookEventName => $event, additionalContext => display_safe("skilletor: in $dir:")."\n$context" );
  }
  return $result;
}

# Claude Code's CwdChanged (spec §8): it is not awaited, and its output takes no context (only
# `watchPaths`), so the line is all it gives – it reaches the user, not the model. It never
# writes the session's cwd record: PostToolUse, fired for the same `cd`, would take it for a move
# already done and answer before this hook's sync is.
sub _cwd_changed {
  my ( $input, $ctx ) = @_;
  my $cwd = _text( $input->{new_cwd} ) // _text( $input->{cwd} ) // return js_ordered();
  my ($out) = _move_checkout( { cwd => $cwd, old_cwd => _text( $input->{old_cwd} ), event => 'CwdChanged', lock_until_deadline => 1 }, $ctx );
  return _truthy( $out->{systemMessage} ) ? js_ordered( systemMessage => $out->{systemMessage} ) : js_ordered();
}

# Claude Code's PostToolUse, which its hooks file runs on a Bash call with a `cd` only (spec §8):
# awaited – the next tool call waits for it – with the cwd after the command as `cwd`, and no old
# one: the session's record stands in. Its context reaches the model.
sub _post_tool_use {
  my ( $input, $ctx ) = @_;
  return _session_move( $input, $ctx, _state($ctx), { event => 'PostToolUse', lock_until_deadline => 1 } );
}

# A move a hook sees only as the session's cwd (the reference's sessionMove): Codex's and Hermes'
# prompt hook – a session there moves only between turns, and that hook is the first to see the
# new cwd, awaited, before the model's request (k149) – and Claude Code's PostToolUse on a Bash
# `cd`.
# The cwd the session's hook last looked at is kept per session id (written at SessionStart): the
# same cwd again asks nothing; another goes to the move core, which tells a move within one
# checkout from one into another. A move that answered for its checkout marks it checked, so the
# interval check starts no second sync of it beside this one.
sub _session_move {
  my ( $input, $ctx, $state, $event ) = @_;
  my $cwd = _text( $input->{cwd} ) // return js_ordered();
  my $session = _session_of($input);
  my $last = $state->session_cwd($session);
  return js_ordered() if defined $last && same_path( $last, $cwd );
  my ( $out, $answered ) = _move_checkout( { cwd => $cwd, old_cwd => $last, %$event }, $ctx );
  eval {    # the state dir cannot be written: the next move looks again
    $state->mark_checked($answered) if defined $answered;
    $state->put_session_cwd( $session, $cwd );
    1;
  };
  return $out;
}

# A pending report and a move's answer as one (k149): both lines, and – when either has a context –
# both in it, a line standing in for an answer without one. Without a move's answer, the report as
# is.
sub _joined {
  my ( $pending, $moved ) = @_;
  my $context_of = sub { ( ref $_[0]{hookSpecificOutput} eq 'HASH' ? $_[0]{hookSpecificOutput} : {} )->{additionalContext} };
  my $says = sub { $_[0] && ( _truthy( $_[0]{systemMessage} ) || _truthy( $context_of->( $_[0] ) ) ) };
  return $pending // js_ordered() unless $says->($moved);
  return $moved unless $says->($pending);
  my @parts = ( $pending, $moved );
  my $out   = js_ordered();
  my @lines = grep { _truthy($_) } map { $_->{systemMessage} } @parts;
  $out->{systemMessage} = join '; ', @lines if @lines;
  if ( grep { _truthy( $context_of->($_) ) } @parts ) {
    my @context = grep { _truthy($_) } map { _truthy( $context_of->($_) ) ? $context_of->($_) : $_->{systemMessage} } @parts;
    $out->{hookSpecificOutput} = js_ordered( hookEventName => 'UserPromptSubmit', additionalContext => join "\n", @context );
  }
  return $out;
}

# Codex's and Hermes' hooks, which notice a move at the next prompt (k149).
sub _follows_moves { my $h = $_[0]{harness} // ''; return $h eq 'codex' || $h eq 'hermes' }

# Codex's and Hermes' prompt hook follows a move first (k149).
sub _user_prompt_submit {
  my ( $input, $ctx ) = @_;
  my $state = _state($ctx);
  my $key = _project_key( $ctx, $input );
  my $moved = _follows_moves($ctx) ? _session_move( $input, $ctx, $state, { event => 'UserPromptSubmit' } ) : js_ordered();
  my $pending = $state->take_pending_report($key);

  my $interval = DEFAULT_INTERVAL;
  eval {    # a config error: the fallback throttle; the background sync reports it
    require Skilletor::Config;
    $interval = Skilletor::Config->load( home => $ctx->{home}, claude_config_dir => _claude_config_dir($ctx), project_dir => _project_dir_of($ctx) )
      ->check_interval;
    1;
  };

  # checkInterval <= 0 turns the in-session check off entirely (SessionStart still syncs).
  if ( $interval > 0 && $state->is_due( $key, $interval ) ) {
    $state->mark_checked($key);
    ( $ctx->{background} // \&default_background )->($ctx);
  }
  return _joined( $pending, $moved );
}

# Runs in the detached child: sync, then leave the result as a pending report – its stdout
# reaches no one. A sync that dies leaves its error, the line SessionStart would give; one that
# timed out on the sync lock leaves no report – the run that holds the lock reports its own sync
# (spec §6.5) – and the project due, so the next prompt retries.
sub _sync_background {
  my ( $input, $ctx ) = @_;
  my $key = _project_key( $ctx, $input );
  my $state = _state($ctx);
  my $output;
  unless ( eval { $output = _to_output( _engine($ctx)->sync, 'UserPromptSubmit' ); 1 } ) {
    my $err = $@;
    return $state->due_again($key) if _lock_timeout($err);
    $output = _warn( _message($err) );
  }
  $state->put_pending_report( $key, $output ) if _truthy( $output->{systemMessage} ) || $output->{hookSpecificOutput};
  return;
}

# Start `hook __sync-background` of this CLI, detached (the default background).
sub default_background {
  my ( $ctx, $spawn ) = @_;
  my $cmd = $ctx->{self_command} or return;
  ( $spawn // \&spawn_detached )->(
    cmd => [ @$cmd, 'hook', '__sync-background' ],
    env => { %ENV, SKILLETOR_PROJECT_DIR => encode_text( $ctx->{project_dir} // '' ) },
  );
  return;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Skilletor::Hooks - The session hooks – SessionStart, UserPromptSubmit, the background sync and the checkout moves (spec §8)

=head1 VERSION

version 0.008000

=head1 SYNOPSIS

  use Skilletor::Hooks qw( run_hook );

  my $out = run_hook( 'session-start', { source => 'startup', cwd => $dir }, {
    home         => $ENV{HOME},
    project_dir  => $ENV{CLAUDE_PROJECT_DIR},    # undef: the git top level of the input's cwd
    state_root   => "$ENV{HOME}/.claude/skilletor",
    self_command => [ $^X, $0 ],                 # what `default_background` re-runs
  } );
  # {} or { systemMessage => …, hookSpecificOutput => { hookEventName, additionalContext? } }

=head1 DESCRIPTION

The reference's F<src/hooks.ts> for Claude Code, Codex and Hermes: a black box from a hook's
input to its output, which never disturbs the session – every path catches and
says what went wrong in one warning line (C<skilletor: …>, display-safe).
L<Skilletor::CLI> runs it as C<skilletor hook E<lt>eventE<gt>>.

=over 4

=item * C<session-start>: a L<Skilletor::Engine/check> of every source, 5 s
each, marks the project checked; when it says changed, a sync, whose report
(L<Skilletor::Report/report_hook>) is the answer. The sync's 20 s write
deadline starts before the check; an earlier C<deadline> in the hook context
wins. A scope whose sources resolve only after that deadline writes nothing.
With nothing changed, the check's warnings in one line, or the trust requests
as a sync would report them. A sync that timed out on the sync lock leaves the
project due again. The input's
C<cwd> is recorded for its session (C<session-cwd.json>). Under Codex
(C<< harness => 'codex' >>) a new session – C<source> missing, null,
C<startup> or C<clear> – also gets the Codex rules files
(L<Skilletor::Engine/codex_rules_files>) at the start of its context; a
resumed one has them in its history already (spec §14.8). A rules file that
cannot be read is a warning. Under Hermes (C<< harness => 'hermes' >>), while
C<hermes> is no target, the answer ends with the line that says how to opt in
(L<Skilletor::Engine/hermes_opt_in_hint>): after its warning line, joined with
C<; >, and after its context when it has one (spec §16.2, §16.4).

=item * C<user-prompt-submit>: hands out the project's pending report; when
the project is due (C<checkInterval> of the config, 600 s when it cannot be
loaded; 0 or less never), marks it checked and starts the background sync. No
engine is loaded on this path. Under Codex and Hermes the prompt hook first
follows a move, as C<post-tool-use> does below (a session there moves only
between turns): its answer and the pending report come as one, both lines,
and both in the context when either has one.

=item * C<__sync-background>: a sync whose answer becomes the project's pending
report; a lock timeout leaves none, and the project due again.

=item * C<cwd-changed>: the session moved from C<old_cwd> into C<new_cwd>
(else C<cwd>); the checkout moved into is synced (below). Its answer is the
line alone – Claude Code's CwdChanged takes no context – and it writes no
session record.

=item * C<post-tool-use>, after a Bash C<cd>: the session's C<cwd> against
the one its session record names (SessionStart's, or the last move's); the
same cwd asks nothing, another is a move from the recorded one. The answer
has the line and a context for the model; a move that answered for its
checkout marks that checkout checked, and the record moves to the new cwd.

=back

A move into another checkout (spec §8) syncs that checkout – the git top level
of the new cwd, never C<project_dir> – in project scope: nothing happens when it
is the old cwd's checkout, the home dir, has no F<.claude/skilletor.json>, or
its lock already matches its config (a check with C<local>: no source asked).
Otherwise a sync with C<if_changed>, 5 s per source, writes nothing once
C<MOVE_DEADLINE_MS> (20 s) has passed and waits for the sync lock until then;
a trust request is answered without a sync. The line names the checkout
(C<… in E<lt>dirE<gt>>) and what to run there for what is left (C<skilletor
trust E<lt>nameE<gt>>, C<skilletor sync>); a failure is C<cannot sync
E<lt>dirE<gt>: E<lt>messageE<gt> — run there: skilletor sync>. Under Hermes a
sync that added or updated a skill Hermes loads there – its own or the Codex
copy – also names C<hermes skills trust E<lt>dirE<gt>>, in the line and in the
context, as one that may be needed (k152): skilletor does not read Hermes'
list of trusted projects.

Without C<project_dir> the project is the git top level of the input's C<cwd>,
else of the process's (L</project_root_of>). The project dir is also the key of
the check mark and the pending report.

=head2 run_hook

  my $out = run_hook( $event, \%input, \%ctx );

Never dies. C<%ctx>: C<home>, C<project_dir>, C<state_root>, C<harness>,
C<claude_config_dir> (default C<CLAUDE_CONFIG_DIR>), C<self_command>,
C<background> (a code ref called with the context instead of
L</default_background>), C<deadline> (an absolute epoch ms write deadline;
SessionStart and checkout moves default to C<MOVE_DEADLINE_MS>, without
relaxing an earlier value) and C<engine>, more arguments of
L<Skilletor::Engine/new> (C<markers>, C<timeout_ms>, C<lock_timeout_ms>, …),
which win over the hook's own – a C<lock_timeout_ms> there over a move's wait
until its deadline as well.

=head2 default_background

  default_background( \%ctx );
  default_background( \%ctx, $spawn );   # $spawn->( cmd => [...], env => {...} ) instead

Starts C<< @{ $ctx->{self_command} } hook __sync-background >> with
L<Skilletor::Process/spawn_detached>: detached, its own session, no stdio, the
environment with C<SKILLETOR_PROJECT_DIR> set to the project. Without
C<self_command> it starts nothing.

=head2 project_root_of

  my $root = project_root_of($cwd);

C<git -C $cwd rev-parse --show-toplevel> in git's environment
(L<Skilletor::GitEnv>), given 2 seconds; when git fails, times out or prints
nothing, C<$cwd> itself.

=head2 SESSION_START_TIMEOUT_MS

=head2 DEFAULT_INTERVAL

=head2 MOVE_DEADLINE_MS

=head1 SUPPORT

=head2 Issues

Please report bugs and feature requests at
L<https://github.com/Getty/skilletor/issues>.

=head1 CONTRIBUTING

Contributions are welcome! Please fork the repository and submit a pull request.

=head1 AUTHOR

Torsten Raudssus <torsten@raudssus.de>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2026 by Torsten Raudssus <torsten@raudssus.de> L<https://raudssus.de/>.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
