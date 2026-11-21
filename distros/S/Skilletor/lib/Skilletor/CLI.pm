package Skilletor::CLI;
# ABSTRACT: The skilletor command line – arguments, usage, exit codes (spec §7)

use strict;
use warnings;
use utf8;

use Exporter qw( import );

our $VERSION = '0.008000';

our @EXPORT_OK = qw( run parse_flags unknown_option project_root_of self_command is_packed USAGE );

# Every module beyond Exporter is loaded by the first call that needs it (k199): --version and
# --help load nothing else, nor does a usage error; a hook loads its own. Each helper below
# loads its module and hands over the call as it was.
sub decode_utf8_lossy { require Skilletor::FSUtil; goto &Skilletor::FSUtil::decode_utf8_lossy }
sub path_join         { require Skilletor::FSUtil; goto &Skilletor::FSUtil::path_join }
sub project_root_of   { require Skilletor::Hooks;  goto &Skilletor::Hooks::project_root_of }
sub js_ordered        { require Skilletor::JSON;   goto &Skilletor::JSON::js_ordered }
sub js_parse          { require Skilletor::JSON;   goto &Skilletor::JSON::js_parse }
sub js_stringify      { require Skilletor::JSON;   goto &Skilletor::JSON::js_stringify }
sub js_type           { require Skilletor::JSON;   goto &Skilletor::JSON::js_type }
sub backend_label     { require Skilletor::Report; goto &Skilletor::Report::backend_label }
sub report_json       { require Skilletor::Report; goto &Skilletor::Report::report_json }
sub report_text       { require Skilletor::Report; goto &Skilletor::Report::report_text }
sub status_text       { require Skilletor::Report; goto &Skilletor::Report::status_text }

# A line of printable ASCII and tabs has nothing to escape (t/68-cli.t holds display_safe to
# that), so a usage error loads no report module either.
sub display_safe {
  return $_[0] if defined $_[0] && $_[0] =~ /\A[\t\x20-\x7E]*\z/;
  require Skilletor::Report;
  goto &Skilletor::Report::display_safe;
}

# An argument as Encode::decode reads it, Encode loaded for one that is not ASCII alone: ASCII
# decodes to itself, a character string.
sub _decode {
  my ( $bytes ) = @_;
  return undef unless defined $bytes;
  if ( $bytes =~ /[^\x00-\x7F]/ ) {
    require Encode;
    return Encode::decode( 'UTF-8', $bytes );
  }
  utf8::upgrade( my $text = $bytes );
  return $text;
}

# The version the CLI reports is the dist's, $VERSION above: x.yyyzzz is the plugin's x.y.z
# (package.json; 0.008000 is 0.8.0), which t/02-version.t ties to it. The usage text starts with it.
use constant USAGE_BODY => <<'END_USAGE';
Remote skills, agents and rules for Claude Code, Codex and Hermes Agent.

Usage:
  skilletor <command> [options]

Commands:
  sync                  Reconcile installed items with the config
  check                 Report whether a sync is due (writes nothing)
  status                Show declared vs. installed items
  add [name] <spec>     Add and trust a source, then sync
  source list           List declared sources
  source remove <name>  Remove a source, then sync
  available [source]    List items offered by trusted sources
  install <item>...     Install items ([type:]name@source), then sync;
                        type:*@source installs every item of that type,
                        type:perl-*@source every one whose name matches;
                        bundle:name@source installs a bundle (a bare
                        name@source does too when no item has that name);
                        sources a bundle needs are offered for adding
                        (on a terminal; otherwise the add commands are shown)
  uninstall <item>...   Remove entries ([type:]name@source, type:*@source,
                        type:perl-*@source or bundle:name@source), then sync
  trust <source>        Trust a project-declared source

Options:
  --scope <s>           user | project | all (default: all; sync, check, status)
  --project             Edit the project config instead of the user config
                        (add, install, uninstall, source remove)
  --json                Machine-readable output
                        (sync, check, status, source list, available)
  --force               sync: adopt foreign files on conflict;
                        source remove: remove even if items are installed
  --project-dir <dir>   Project root (default: git top level of cwd, else cwd)
  -h, --help            Show this help (anywhere; nothing else runs)
  -v, --version         Show the version (first argument only)

An option the command does not accept is an error (exit 2).
END_USAGE
sub USAGE () { 'skilletor '.$VERSION."\n".USAGE_BODY }

# The options each command accepts (spec §7); --project-dir goes with every one. `hook` is
# absent: it is internal and must never fail (spec §8).
my %ACCEPTED = (
  sync            => [qw( --scope --json --force )],
  check           => [qw( --scope --json )],
  status          => [qw( --scope --json )],
  add             => [qw( --project )],
  'source list'   => [qw( --json )],
  'source remove' => [qw( --project --force )],
  available       => [qw( --json )],
  install         => [qw( --project )],
  uninstall       => [qw( --project )],
  trust           => [],
);

# The reference's `source ${rest[0]}`: an absent sub-command is the string "undefined".
sub _source_key { 'source '.( $_[0]{rest}[0] // 'undefined' ) }

sub unknown_option {
  my ( $cmd, $flags ) = @_;
  return undef if $cmd ne 'source' && !exists $ACCEPTED{$cmd};    # unknown command: its own error
  my $key = $cmd eq 'source' ? _source_key($flags) : $cmd;
  # `source` without list/remove keeps its own usage error; any known option is fine there.
  my $accepted = $ACCEPTED{$key} // ( $cmd eq 'source' ? [ @{ $ACCEPTED{'source list'} }, @{ $ACCEPTED{'source remove'} } ] : [] );
  my %ok = map { ( $_ => 1 ) } @$accepted;
  return ( grep { $_ ne '--project-dir' && !$ok{$_} } @{ $flags->{options} } )[0];
}

sub parse_flags {
  my ( @args ) = @_;
  my %flags = ( scope => 'all', json => 0, force => 0, project => 0, project_dir => undef, options => [], rest => [] );
  for ( my $i = 0; $i < @args; $i++ ) {
    my $arg = $args[$i];
    push @{ $flags{options} }, ( $arg =~ /\A--/ ? $arg =~ s/=.*//sr : $arg ) if $arg =~ /\A-/;
    if    ( $arg eq '--json' )                  { $flags{json}        = 1 }
    elsif ( $arg eq '--force' )                 { $flags{force}       = 1 }
    elsif ( $arg eq '--project' )               { $flags{project}     = 1 }
    elsif ( $arg eq '--scope' )                 { $flags{scope}       = $args[ ++$i ] }    # undef past the end
    elsif ( $arg =~ /\A--scope=(.*)\z/s )       { $flags{scope}       = $1 }
    elsif ( $arg eq '--project-dir' )           { $flags{project_dir} = $args[ ++$i ] }
    elsif ( $arg =~ /\A--project-dir=(.*)\z/s ) { $flags{project_dir} = $1 }
    else                                        { push @{ $flags{rest} }, $arg }
  }
  return \%flags;
}

# Text to a stream as UTF-8, as Node writes a string. ASCII is its own UTF-8: Encode is loaded
# for other text only.
sub _write {
  my ( $fh, $text ) = @_;
  if ( $text =~ /[^\x00-\x7F]/ ) {
    require Encode;
    $text = Encode::encode( 'UTF-8', $text );
  }
  print {$fh} $text;
}

# Display lines, each escaped whole (spec §8), one newline after each.
sub _print_lines {
  my ( $fh, @lines ) = @_;
  _write( $fh, join( "\n", map { display_safe($_) } @lines )."\n" );
}

# Text whose newlines are line breaks, each line escaped.
sub _print_text {
  my ( $fh, $text ) = @_;
  my @lines = split /\n/, $text, -1;
  _print_lines( $fh, @lines ? @lines : ('') );
}

# A string's truthiness in JavaScript: set and not empty.
sub _truthy { defined $_[0] && length $_[0] }

# Node's os.homedir(): $HOME, else the user's passwd entry.
sub _home {
  return decode_utf8_lossy( $ENV{HOME} ) if defined $ENV{HOME};
  my $dir = ( getpwuid $< )[7];
  die "A system error occurred: uv_os_homedir returned ENOENT (no such file or directory)\n" unless defined $dir;
  return decode_utf8_lossy($dir);
}

# The engine a command runs on, as the reference's makeContext builds it: the home, the project
# from --project-dir (a relative one taken from cwd: the scope's state is keyed by its absolute lock
# path, k254) or the git top level of cwd. The rest is the engine's own default, read from this
# machine: the state root <CLAUDE_CONFIG_DIR or ~/.claude>/skilletor, host and user, the harness
# markers, git's answers.
sub _engine {
  my ( $flags ) = @_;
  require Skilletor::Engine;    # loaded for the commands that run it: --help and usage errors stay fast
  require Skilletor::FSUtil;
  my $home = _home();
  my $project_dir = $flags->{project_dir};
  unless ( defined $project_dir && ( $project_dir eq '' || Skilletor::FSUtil::is_absolute($project_dir) ) ) {
    require Cwd;
    my $cwd = Cwd::getcwd();
    die "the current directory no longer exists; pass --project-dir <dir>\n" unless defined $cwd;
    $cwd = decode_utf8_lossy($cwd);
    $project_dir = defined $project_dir ? Skilletor::FSUtil::path_resolve( $cwd, $project_dir ) : project_root_of($cwd);
  }
  return Skilletor::Engine->new( home => $home, project_dir => $project_dir );
}

# The sync report, or "up to date" when no scope has anything to say; run-level warnings and
# notes come in addition, never instead (the reference's syncText).
sub _sync_text {
  my ( $r ) = @_;
  my $text = report_text($r);
  my $run_level = @{ $r->{warnings} // [] } || @{ $r->{notes} // [] };
  if ($run_level) {
    my %scopes_only = %$r;
    delete @scopes_only{qw( warnings notes )};
    return "skilletor: up to date\n$text" unless length report_text( \%scopes_only );
  }
  return length $text ? $text : 'skilletor: up to date';
}

# A sync that stopped at a config error (spec §7): its report on stderr, exit 2. With `saved`,
# the config file the command's edit wrote before the sync: it stays, and the lines say so
# (k103).
sub _sync_failed {
  my ( $r, %opts ) = @_;
  if ( !defined $opts{saved} ) {
    _print_text( \*STDERR, $opts{json} ? report_json($r) : report_text($r) );
  }
  else {
    _print_lines( \*STDERR, 'skilletor: config error, nothing synced — '.$r->{error},
      'skilletor: the config edit itself was saved in '.$opts{saved}.' (not rolled back); fix the error, then run skilletor sync' );
  }
  return 2;
}

sub _sync {
  my ( $flags ) = @_;
  my $r = _engine($flags)->sync( scope => $flags->{scope}, force => $flags->{force} );
  return _sync_failed( $r, json => $flags->{json} ) if _truthy( $r->{error} );
  _print_text( \*STDOUT, $flags->{json} ? report_json($r) : _sync_text($r) );
  return 0;
}

sub _check {
  my ( $flags ) = @_;
  my $r = _engine($flags)->check( scope => $flags->{scope} );
  if ( _truthy( $r->{error} ) ) {    # a line, never JSON – under --json too
    _print_lines( \*STDERR, 'skilletor: '.$r->{error} );
    return 2;
  }
  _print_text( \*STDOUT, $flags->{json} ? report_json($r) : $r->{changed} ? 'changed' : 'up to date' );
  return $r->{changed} ? 1 : 0;
}

sub _status {
  my ( $flags ) = @_;
  my $r = _engine($flags)->status( scope => $flags->{scope} );
  _print_text( \*STDOUT, $flags->{json} ? report_json($r) : status_text($r) );    # an error too: stdout, exit 2
  return _truthy( $r->{error} ) ? 2 : 0;
}

# The config commands; Skilletor::Commands is loaded for them alone, as the engine is.
sub _source_list {
  my ( $flags ) = @_;
  my $engine = _engine($flags);
  require Skilletor::Commands;
  my $list = Skilletor::Commands::source_list($engine);
  if ( $flags->{json} ) {
    _print_text( \*STDOUT, js_stringify( $list, 2 ) );
  }
  else {
    _print_lines( \*STDOUT, map { $_->{name}.' ['.$_->{origin}.'] '.js_stringify( $_->{def} ) } @$list );
  }
  return 0;
}

# The added or kept line, then the sync's text. A kept entry wrote nothing to the config: a sync
# that stopped at a config error says so as sync does.
sub _add {
  my ( $flags ) = @_;
  my @rest = @{ $flags->{rest} };
  my ( $name, $spec ) = @rest >= 2 ? @rest[ 0, 1 ] : ( undef, $rest[0] );
  my $engine = _engine($flags);
  require Skilletor::Commands;
  my $r = Skilletor::Commands::add( $engine, name => $name, spec => $spec, project => $flags->{project} );
  my $def = js_stringify( $r->{def} );
  _print_lines( \*STDOUT, $r->{kept} ? "source $r->{name} already added ($def), kept as is" : "added source $r->{name} ($def)" );
  if ( _truthy( $r->{report}{error} ) ) {
    return _sync_failed( $r->{report}, saved => $r->{kept} ? undef : Skilletor::Commands::config_path( $engine, $flags->{project} ) );
  }
  _print_text( \*STDOUT, _sync_text( $r->{report} ) );
  return 0;
}

# The sync's report after the edit, or `removed source <name>` when it has nothing to say.
sub _source_remove {
  my ( $flags, $name ) = @_;
  my $engine = _engine($flags);
  require Skilletor::Commands;
  my $r = Skilletor::Commands::source_remove( $engine, name => $name, project => $flags->{project}, force => $flags->{force} );
  return _sync_failed( $r, saved => Skilletor::Commands::config_path( $engine, $flags->{project} ) ) if _truthy( $r->{error} );
  my $text = report_text($r);
  _print_text( \*STDOUT, length $text ? $text : display_safe("removed source $name") );
  return 0;
}

# One line per item – installed mark, type, name@source, description – and a second, indented,
# for an item's error, a bundle's members or why it does not expand; --json the list.
sub _available {
  my ( $flags ) = @_;
  my $engine = _engine($flags);
  require Skilletor::Commands;
  my $items = Skilletor::Commands::available( $engine, source => $flags->{rest}[0] );
  if ( $flags->{json} ) {
    _print_text( \*STDOUT, js_stringify( $items, 2 ) );
    return 0;
  }
  my @lines = map {
    my $i = $_;
    my $line = ( $i->{installed} ? '✓' : ' ' ).' '.$i->{type}.' '.$i->{name}.'@'.$i->{source}
      .( _truthy( $i->{description} ) ? ' — '.$i->{description} : '' );
    # An item that cannot be built (spec §4.1) says why on the next line, as a bundle does;
    # a bundle's members (spec §15.5) go there, or why it cannot be expanded.
      $i->{type} ne 'bundle' ? ( $line, defined $i->{error} ? '    error: '.$i->{error} : () )
    : defined $i->{error}    ? ( $line, '    error: '.$i->{error} )
    :                          ( $line, '    '.( join( ', ', @{ $i->{members} } ) || '(no items)' ) );
  } @$items;
  _print_lines( \*STDOUT, @lines );
  return 0;
}

# The sync's text after the edit. A bundle's missing sources are asked for on a terminal.
sub _install {
  my ( $flags ) = @_;
  my $engine = _engine($flags);
  require Skilletor::Commands;
  my $r = Skilletor::Commands::install( $engine, items => $flags->{rest}, project => $flags->{project}, prompt => _tty_prompter() );
  return _sync_failed( $r, saved => Skilletor::Commands::config_path( $engine, $flags->{project} ) ) if _truthy( $r->{error} );
  _print_text( \*STDOUT, _sync_text($r) );
  return 0;
}

# The sync's text after the edit. A warning names each covering wildcard or bundle that remains.
sub _uninstall {
  my ( $flags ) = @_;
  my $engine = _engine($flags);
  require Skilletor::Commands;
  my $r = Skilletor::Commands::uninstall( $engine, items => $flags->{rest}, project => $flags->{project} );
  _print_lines( \*STDERR, 'skilletor: warning: '.$_ ) for @{ $r->{hints} };
  return _sync_failed( $r->{report}, saved => Skilletor::Commands::config_path( $engine, $flags->{project} ) )
    if _truthy( $r->{report}{error} );
  _print_text( \*STDOUT, _sync_text( $r->{report} ) );
  return 0;
}

# Questions on the terminal (the reference's ttyPrompter): stdin in, stderr out, so stdout stays
# clean; none unless both are terminals. The end of input (Ctrl+D) and Ctrl+C abort the command
# with the message Node's readline gives.
sub _tty_prompter {
  return undef unless -t STDIN && -t STDERR;
  return sub {
    my ( $question ) = @_;
    _write( \*STDERR, display_safe($question).' ' );
    local $SIG{INT} = sub { die "Aborted with Ctrl+C\n" };
    binmode STDIN;
    my $line = <STDIN>;
    die "Aborted with Ctrl+D\n" unless defined $line;
    $line =~ s/\r?\n\z//;
    return decode_utf8_lossy($line);
  };
}

sub _trust {
  my ( $flags, $name ) = @_;
  my $engine = _engine($flags);
  require Skilletor::Commands;
  my $r = Skilletor::Commands::trust( $engine, $name );
  _print_lines( \*STDOUT, 'trusted source '.$r->{name}.' ('.backend_label($r).')' );
  return 0;
}

# A usage error (spec §7): its line on stderr, exit 2.
sub _usage_error {
  my ( $line ) = @_;
  _write( \*STDERR, "$line\n" );
  return 2;
}

# What a caught error says: a Skilletor::Error's message, else Perl's text without the
# " at FILE line N." it appends.
sub _message {
  my ( $err ) = @_;
  require Scalar::Util;
  return $err->message if Scalar::Util::blessed($err) && $err->can('message');
  my $text = "$err";
  $text =~ s/ at (?:(?! at ).)+ line \d+(?:, <[^>]*> (?:line|chunk) \d+)?\.\n\z//s;
  chomp $text;
  return $text;
}

#### hook ####################################################################

# Is this a PAR-packed binary? PAR's loader is loaded and names the program in PAR_PROGNAME.
sub is_packed { exists $INC{'PAR.pm'} && _truthy( $ENV{PAR_PROGNAME} ) ? 1 : 0 }

# The command line that runs this CLI once more, for the hooks' detached background sync (the
# reference's binPath). A PAR-packed binary is its own program: PAR_PROGNAME, its full path – in
# one, $^X is the bare name `perl` and $0 the name it was called by. Plain perl runs $^X with the
# script and, as -I, every module dir it searches, so the child finds what this run found.
sub self_command {
  my ( %args ) = @_;
  my $packed = $args{packed} // is_packed();
  return [ $args{progname} // $ENV{PAR_PROGNAME} ] if $packed;
  return [ $args{perl} // $^X, ( map { "-I$_" } grep { !ref } @{ $args{inc} // \@INC } ), $args{script} // $0 ];
}

# JavaScript's truthiness of a JSON value.
sub _js_truthy {
  my ( $v ) = @_;
  my $type = js_type($v);
  return 0 if $type eq 'null';
  return length $v ? 1 : 0 if $type eq 'string';
  return $v ? 1 : 0 if $type eq 'number' || $type eq 'boolean';
  return 1;
}

# The hook's input: stdin as JSON, nothing on a terminal; malformed input, or JSON that is no
# object, counts as none.
sub _hook_input {
  return {} if -t STDIN;
  my $raw = do { no warnings; local $/; binmode STDIN; <STDIN> } // '';
  my $input = eval { $raw =~ /\S/ ? js_parse( decode_utf8_lossy($raw) ) : undef };
  return js_type($input) eq 'object' ? $input : {};
}

# `skilletor hook <event> [--harness codex|hermes]` (the reference's runHookCommand): stdin JSON
# in, a compact JSON line out when there is something to say, exit 0 always (spec §8). A die in
# its own setup – no home, say (k164) – is that one line as well.
sub _hook {
  my ( @args ) = @_;
  local $SIG{PIPE} = 'IGNORE';    # a reader gone is no reason to exit otherwise
  my $out;
  $out = js_ordered( systemMessage => display_safe( 'skilletor: '._message($@) ) ) unless eval { $out = _hook_output(@args); 1 };
  if ( ref $out eq 'HASH' && ( _js_truthy( $out->{systemMessage} ) || _js_truthy( $out->{hookSpecificOutput} ) ) ) {
    _write( \*STDOUT, js_stringify($out)."\n" );
  }
  return 0;
}

sub _hook_output {
  my ( @args ) = @_;
  my $event = $args[0];
  my ($at) = grep { $args[$_] eq '--harness' } 0 .. $#args;
  my $harness = defined $at ? $args[ $at + 1 ] : ( map { /\A--harness=(.*)\z/s ? $1 : () } @args )[0];
  return undef unless _truthy($event);    # nothing to do, never disturb the session
  my $input = _hook_input();
  my $home  = _home();
  # Unset under Codex: the hook then takes the git top level of the input's cwd (spec §14.5).
  my ($project_dir) = grep { _truthy($_) } map { defined $_ ? decode_utf8_lossy($_) : undef } @ENV{qw( SKILLETOR_PROJECT_DIR CLAUDE_PROJECT_DIR )};
  my $config_dir = _truthy( $ENV{CLAUDE_CONFIG_DIR} ) ? decode_utf8_lossy( $ENV{CLAUDE_CONFIG_DIR} ) : undef;
  my %ctx = (
    home              => $home,
    project_dir       => $project_dir,
    claude_config_dir => $config_dir,
    state_root        => path_join( $config_dir // path_join( $home, '.claude' ), 'skilletor' ),
    self_command      => self_command(),
  );
  $ctx{harness} = $harness if defined $harness && ( $harness eq 'codex' || $harness eq 'hermes' );
  require Skilletor::Hooks;
  return Skilletor::Hooks::run_hook( $event, $input, \%ctx );
}

sub run {
  my ( @argv ) = map { _decode($_) } @_;
  # Argument hygiene (spec §7): --version only first, --help anywhere and alone.
  if ( @argv && ( $argv[0] eq '--version' || $argv[0] eq '-v' ) ) {
    _write( \*STDOUT, $VERSION."\n" );
    return 0;
  }
  if ( !@argv || grep { $_ eq '--help' || $_ eq '-h' } @argv ) {
    _write( \*STDOUT, USAGE );    # no command has its own help yet
    return 0;
  }

  my $cmd = $argv[0];
  if ( $cmd =~ /\A-/ ) {
    _print_lines( \*STDERR, "skilletor: unknown option: $cmd (run skilletor --help)" );
    return 2;
  }
  my $flags = parse_flags( @argv[ 1 .. $#argv ] );
  # Ahead of every check (k164): a hook never fails on its arguments, and it takes its project
  # from its environment or input, not from the process cwd – which may be gone.
  return _hook( @{ $flags->{rest} } ) if $cmd eq 'hook';
  my $unknown = unknown_option( $cmd, $flags );
  if ( defined $unknown ) {
    my $name = $cmd eq 'source' && exists $ACCEPTED{ _source_key($flags) } ? _source_key($flags) : $cmd;
    _print_lines( \*STDERR, "skilletor: unknown option for $name: $unknown (run skilletor --help)" );
    return 2;
  }
  my $scope = $flags->{scope};
  if ( !defined $scope || !grep { $scope eq $_ } qw( user project all ) ) {
    _print_lines( \*STDERR, 'skilletor: invalid --scope: '.( $scope // 'undefined' ) );
    return 2;
  }

  my $code;
  return $code if eval { $code = _dispatch( $cmd, $flags ); 1 };
  _print_text( \*STDERR, 'skilletor: '._message($@) );
  return 1;
}

sub _dispatch {
  my ( $cmd, $flags ) = @_;
  my @rest = @{ $flags->{rest} };
  my $given = sub { defined $_[0] && length $_[0] };    # JavaScript's truthiness of a string
  return _sync($flags)   if $cmd eq 'sync';
  return _check($flags)  if $cmd eq 'check';
  return _status($flags) if $cmd eq 'status';
  return _available($flags) if $cmd eq 'available';
  if ( $cmd eq 'add' ) {
    return _usage_error('skilletor: add needs a source spec') unless @rest;
    return _add($flags);
  }
  if ( $cmd eq 'source' ) {
    my $sub = $rest[0] // '';
    return _source_list($flags) if $sub eq 'list';
    if ( $sub eq 'remove' ) {
      return _usage_error('skilletor: source remove needs a name') unless $given->( $rest[1] );
      return _source_remove( $flags, $rest[1] );
    }
    return _usage_error('skilletor: usage: source list | source remove <name>');
  }
  if ( $cmd eq 'install' || $cmd eq 'uninstall' ) {
    return _usage_error("skilletor: $cmd needs at least one item") unless @rest;
    return $cmd eq 'install' ? _install($flags) : _uninstall($flags);
  }
  if ( $cmd eq 'trust' ) {
    return _usage_error('skilletor: trust needs a source name') unless $given->( $rest[0] );
    return _trust( $flags, $rest[0] );
  }
  _print_lines( \*STDERR, "skilletor: unknown command: $cmd" );
  return 2;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Skilletor::CLI - The skilletor command line – arguments, usage, exit codes (spec §7)

=head1 VERSION

version 0.008000

=head1 SYNOPSIS

  use Skilletor::CLI;
  exit Skilletor::CLI::run(@ARGV);

=head1 DESCRIPTION

The command line of the Perl port, after the reference's F<src/cli.ts>: the
same usage text, version, options, error lines and exit codes, byte for byte –
the shared conformance cases (F<../conformance>, op C<cli>) run either CLI
against the same expectations.

It runs C<sync>, C<check> and C<status> on L<Skilletor::Engine>, with
C<--scope>, C<--force> and C<--json> as the reference reads them:

=over 4

=item * C<sync> prints its report, or C<skilletor: up to date> when no scope
has anything to say; C<--json> prints the report as JSON. A config error puts
the report (text, or JSON with C<--json>) on stderr and exits 2.

=item * C<check> prints C<changed> and exits 1 when a sync is due, else
C<up to date> and 0; C<--json> prints the report. An error is the one line
C<skilletor: E<lt>errorE<gt>> on stderr, exit 2 – never JSON, with C<--json>
too.

=item * C<status> prints the declared items per scope, naming its targets unless
they are Claude Code alone; C<--json> prints the report. An error goes to
stdout as well, exit 2.

=back

It runs C<add>, C<trust>, C<source list>, C<source remove>, C<available>,
C<install> and C<uninstall> through L<Skilletor::Commands>:

=over 4

=item * C<add [E<lt>nameE<gt>] E<lt>specE<gt> [--project]> resolves the spec
(a generic host probed, L<Skilletor::Probe>), adds the source to the user
config, or the project config, trusts it and syncs: C<added source
E<lt>nameE<gt> (E<lt>fields as JSONE<gt>)>, or C<source E<lt>nameE<gt> already
added (E<lt>fields as JSONE<gt>), kept as is> when that config has the name at
the same address, then the sync's text. A sync that stops at a config error
exits 2: after an edit with the two lines naming the saved config file (k103),
after a kept entry with the sync's own report.

=item * C<trust E<lt>sourceE<gt>> trusts the source for the backend it would
use now and prints C<trusted source E<lt>nameE<gt> (E<lt>kindE<gt>
E<lt>addressE<gt>)>.

=item * C<source list> prints one line per source, C<E<lt>nameE<gt>
[E<lt>originE<gt>] E<lt>fields as JSONE<gt>>; C<--json> prints the list as
JSON.

=item * C<source remove E<lt>nameE<gt> [--project] [--force]> removes the
source from the user config, or the project config, then syncs: the sync's
report, or C<removed source E<lt>nameE<gt>> when it has nothing to say. A sync
that stops at a config error exits 2 with two lines on stderr naming the saved
config file (k103).

=item * C<available [E<lt>sourceE<gt>]> lists what the trusted sources offer,
or that one source, under the sync lock: per item a line of C<✓> when it is
installed (a blank when not), its type and C<E<lt>nameE<gt>@E<lt>sourceE<gt>>,
then C< — E<lt>descriptionE<gt>> when it has one; under it, indented four
spaces, C<error: E<lt>whyE<gt>> for an item that cannot be built. A bundle's
line is always followed by one: C<error: E<lt>whyE<gt>>, its members joined by
C<, >, or C<(no items)>. C<--json> prints the list as JSON. A source not
trusted is skipped, even by name.

=item * C<install E<lt>itemE<gt>... [--project]> adds each item
(C<[type:]name@source>, C<type:*@source>, C<bundle:name@source>) to the user
config, or the project config, then syncs and prints the sync's text. Every
item is checked first, under the sync lock; one that fails changes nothing. A
bundle naming sources by an address no configured source serves: on a
terminal (stdin and stderr) each is asked for on stderr, a name, the proposed
one or C<n> to skip, and an added one is trusted as C<add> trusts; elsewhere
the command fails naming the C<skilletor add> commands. A sync that stops at a
config error exits 2 with two lines on stderr naming the saved config file
(k103).

=item * C<uninstall E<lt>itemE<gt>... [--project]> removes explicit item,
wildcard or bundle entries from the user or project config, then syncs and
prints its text. Every item is checked before any edit. An item still installed
by a wildcard or bundle leaves a warning on stderr after its explicit entry is
removed; an item with no explicit entry exits 1 and the diagnostic names the
covering entry or where else it is declared. A sync that stops at a config
error exits 2 and names the saved config file.

=back

A refusal or a config file that does not load is C<skilletor: E<lt>whyE<gt>>
on stderr, exit 1, nothing changed.

The engine runs on this machine: the home from C<$HOME>, the project from
C<--project-dir> or the git top level of the working directory
(L</project_root_of>), state under C<$CLAUDE_CONFIG_DIR> or F<~/.claude>, in
F<skilletor/>, and the real host and user for templates. The engine and the
commands are loaded only for the commands that run, every other module by the
first call that needs it, so C<--version>, C<--help> and a usage error in ASCII
load none of them and stay quick.

C<hook E<lt>eventE<gt> [--harness codex|hermes]> runs a hook
(L<Skilletor::Hooks>): the input is stdin's JSON (none on a terminal; malformed
input counts as none), the project C<$SKILLETOR_PROJECT_DIR>, else
C<$CLAUDE_PROJECT_DIR>, else the git top level of the input's C<cwd>. It prints
one compact JSON line when the hook has something to say and exits 0 whatever
happens – a failure is that line's C<systemMessage>, its own setup's too. It is
dispatched before any option check, so no option makes it fail. Its background
sync re-runs this CLI (L</self_command>).

Beside them the CLI has the argument layer: C<--help>, C<--version>, the
options each command accepts, an unknown option or command, an invalid
C<--scope> and a missing operand.

Output is UTF-8; every line a user's input reaches is escaped by
L<Skilletor::Report/display_safe>.

=head2 run

  my $exit = Skilletor::CLI::run(@ARGV);

Runs one command line – the arguments as the operating system passes them,
UTF-8 bytes – writing to C<STDOUT> and C<STDERR>, and returns the exit code: 0,
1 for a failure, 2 for a usage error.

=head2 parse_flags

  my $flags = parse_flags(@args);

The arguments after the command: C<< { scope, json, force, project,
project_dir, options, rest } >>. C<options> lists every option given, by name
(C<--scope=user> is C<--scope>), in order; C<rest> holds the operands and every
option the parser does not know. C<scope> is C<undef> when C<--scope> is the
last argument.

=head2 project_root_of

  my $root = project_root_of($cwd);

The project of a working directory as the reference's hooks and CLI find it;
L<Skilletor::Hooks/project_root_of>, exported here as well.

=head2 self_command

  my $argv = self_command();
  my $argv = self_command( packed => 0, perl => $^X, inc => \@INC, script => $0 );
  my $argv = self_command( packed => 1, progname => $ENV{PAR_PROGNAME} );

The command line that runs this CLI once more, without its arguments – what the
hooks' background sync starts. A PAR-packed binary (L</is_packed>) is its own
program: C<[ $ENV{PAR_PROGNAME} ]>, the binary's full path (in a packed binary
C<$^X> is the bare name C<perl>, and C<$0> the name it was called by). Plain
perl runs C<$^X> with the script C<$0>, and every directory of C<@INC> as C<-I>,
so the child loads the same modules. Each part can be given, for a test.

=head2 is_packed

True in a PAR-packed binary: PAR's loader is loaded (C<$INC{'PAR.pm'}>) and
names the program in C<PAR_PROGNAME>.

=head2 unknown_option

  my $option = unknown_option( $cmd, $flags );

The first option C<$cmd> does not accept, or C<undef>.

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
