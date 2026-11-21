package Skilletor::Engine;
# ABSTRACT: sync, check and status for Claude Code, Codex and Hermes – the reference's engine pipeline after the resolve

use Moo;
use utf8;
use Carp qw( croak );
use Encode ();
use JSON::MaybeXS ();
use Scalar::Util qw( blessed refaddr );
use Skilletor::AgentsMD qw(
  RULES_FILE codex_hook_trusted inspect_agents_md parse_rules_file pointer_lines project_doc_limit rules_file_text with_block
);
use Skilletor::Apply qw( apply );
use Skilletor::Backend;
use Skilletor::Briefing qw( briefing_warning missing_skills skill_roots );
use Skilletor::Bundles qw( matches_pattern );
use Skilletor::ClaudeSettings qw( plan_claude_settings );
use Skilletor::Config;
use Skilletor::Convert qw( convert_for_target );
use Skilletor::Entry qw( HARNESSES ITEM_TYPES );
use Skilletor::FSUtil qw(
  decode_utf8_lossy encode_text hash_bytes is_absolute node_fs_error path_join path_resolve read_text same_file same_path to_posix write_text
);
use Skilletor::Gitignore qw(
  CODEX_ENTRIES LOCAL_ENTRIES PROJECT_CLAUDE_ENTRIES SKILL_GITIGNORE WORKTREE_INCLUDE
  block_entries has_block skill_gitignore_path update_gitignore update_worktree_include with_skill_gitignore
);
use Skilletor::GitEnv qw( git_env );
use Skilletor::JSON qw( js_ordered js_sort_keys js_stringify js_type );
use Skilletor::Lock qw( key_to_type_name parse_lock_key read_lock write_lock );
use Skilletor::Process qw( run_command );
use Skilletor::Render qw( build executables renders_empty );
use Skilletor::Report qw( empty_scope_report );
use Skilletor::Source::Git;
use Skilletor::Source::Local;
use Skilletor::Source::Url;
use Skilletor::State;
use Skilletor::Targets qw(
  all_roots default_hermes_home detect_harnesses detect_project_harnesses is_block_type is_local_type lacks_local_prefix lock_key
  place_output receivers root_of root_of_key select_targets served_via supports target_gaps
);
use Sys::Hostname ();
use Time::HiRes ();
use namespace::clean;

extends 'Skilletor::Resolver';

our $VERSION = '0.008000';

# What a sync makes of unchanged sources and inputs (the reference's RENDER_FORMAT, k107): part
# of the render-inputs hash, so both implementations record and compare the same one.
use constant RENDER_FORMAT => 2;

my %TYPE_DIR = ( skill => 'skills', agent => 'agents', rule => 'rules' );

# process.platform where Perl's $^O names the system otherwise.
my %NODE_PLATFORM = ( MSWin32 => 'win32', solaris => 'sunos' );

# Does a user-scope root lie inside a git work tree (spec §6.4)? Default: ask git.
has is_git_work_tree => (
  is      => 'ro',
  default => sub { \&Skilletor::Gitignore::is_git_work_tree },
);

# Which of the paths (relative to a root) does git track? Default: one `git ls-files`.
has git_tracked => (
  is      => 'ro',
  default => sub { \&Skilletor::Gitignore::git_tracked },
);

# The project's `origin` remote, a render input of the project scope. Default: ask git.
has git_remote => (
  is      => 'ro',
  default => sub { \&_git_remote },
);

# `$HERMES_HOME` (spec §16.2): the root of user-scope Hermes skills – the Hermes plugin passes its
# session's. Unset or empty: the home the last user-scope sync recorded, else Hermes' default.
has hermes_home => (
  is      => 'lazy',
  builder => sub { defined $ENV{HERMES_HOME} ? decode_utf8_lossy( $ENV{HERMES_HOME} ) : undef },
);

# `CLAUDE_PLUGIN_ROOT`: the running plugin's install, naming skilletor's marketplace (spec §6.8).
has plugin_root => (
  is      => 'lazy',
  builder => sub { defined $ENV{CLAUDE_PLUGIN_ROOT} ? decode_utf8_lossy( $ENV{CLAUDE_PLUGIN_ROOT} ) : undef },
);

# The render context's `host` (spec §5). Default: this machine's name and OS, as Node names them.
has host => (
  is      => 'lazy',
  builder => sub { js_ordered( name => Sys::Hostname::hostname(), os => $NODE_PLATFORM{$^O} // $^O ) },
);

# The render context's `user` (spec §5). Default: the login name, as Node's os.userInfo() finds
# it, and the engine's home.
has user => (
  is      => 'lazy',
  builder => sub { js_ordered( name => _user_name(), home => $_[0]->home ) },
);

# Node's os.userInfo().username: the effective user's passwd entry (Windows: the account name).
# Without an entry Node throws, and the reference's build of every item fails with its message.
sub _user_name {
  return $ENV{USERNAME} // '' if $^O eq 'MSWin32';
  my $name = getpwuid $>;
  die "A system error occurred: uv_os_get_passwd returned ENOENT (no such file or directory)\n" unless defined $name;
  return Encode::decode( 'UTF-8', $name );
}

sub _git_remote {
  my ( $dir ) = @_;
  my $r = eval { run_command( cmd => [ 'git', '-C', $dir, 'remote', 'get-url', 'origin' ], env => git_env() ) };
  return '' unless $r && !$r->{spawn_error} && defined $r->{code} && $r->{code} == 0;
  ( my $out = Encode::decode( 'UTF-8', $r->{stdout} ) ) =~ s/\A\s+|\s+\z//g;
  return $out;
}

sub _message {
  my ( $err ) = @_;
  return $err->message if blessed $err && $err->can('message');
  return ( "$err" =~ s/ at \S+ line \d+\.?\n?\z//r =~ s/\n\z//r );
}

# The clock a sync's deadline is compared with: epoch ms, as Date.now().
sub _now_ms { int( Time::HiRes::time() * 1000 ) }

sub _true  { JSON::MaybeXS::true() }
sub _false { JSON::MaybeXS::false() }

# Do two texts, either one undef (no file), differ?
sub _differs {
  my ( $x, $y ) = @_;
  return defined $x ? !defined $y || $x ne $y : defined $y;
}

sub _uniq {
  my %seen;
  return grep { !$seen{$_}++ } @_;
}

#### Paths ###################################################################

# path.relative (posix) of two absolute paths.
sub _relative {
  my ( $from, $to ) = @_;
  my @f = grep { length } split m{/}, path_resolve($from);
  my @t = grep { length } split m{/}, path_resolve($to);
  while ( @f && @t && $f[0] eq $t[0] ) { shift @f; shift @t }
  return join '/', ( map {'..'} @f ), @t;
}

sub _codex_home_of {
  my ( $self ) = @_;
  my $cx = $self->codex_home;
  return ( defined $cx && length $cx ) ? $cx : undef;
}

sub _lock_path  { my ( $self, $scope ) = @_; return path_join( $self->_target_dir($scope), 'skilletor.lock.json' ) }

# Hermes' default home for this machine (`~/.hermes`; `%LOCALAPPDATA%\hermes` on Windows).
sub _hermes_default { default_hermes_home( $_[0]->home ) }

# The Hermes home the user scope's `hermes:` entries were last synced under (spec §16.2): the
# recorded one, else the default. Never dies: a state dir that cannot be read is the default.
sub _recorded_hermes_home {
  my ( $self ) = @_;
  my $recorded = eval { Skilletor::State->new( root => $self->state_root )->hermes_home };
  return $recorded // $self->_hermes_default;
}

# The Hermes home this run serves (spec §16.2): `$HERMES_HOME` (L</hermes_home>), else the
# recorded one, else Hermes' default. So a run no Hermes started – a Claude Code session – sees
# the same home, and with it the same targets and root, as the Hermes session before it.
sub _hermes_home_of {
  my ( $self ) = @_;
  my $given = $self->hermes_home;
  return $self->_recorded_hermes_home unless defined $given && length $given;
  return path_resolve( Skilletor::Source::Local->expand_home( $given, $self->home ) );
}

# Where a scope's roots live (spec §14.2, §16.2).
sub _root_context {
  my ( $self, $scope ) = @_;
  return {
    base        => $self->_base_of($scope),
    scope       => $scope,
    claude_dir  => $self->claude_dir,
    codex_home  => $self->_codex_home_of,
    hermes_home => $self->_hermes_home_of,
  };
}

# A path for the commit hint and the tracked warning: relative to the project, `~/…` in the user
# scope, absolute outside the scope's base.
sub _scope_label {
  my ( $scope, $base, $abs ) = @_;
  my $rel = _relative( $base, $abs );
  return $abs if $rel =~ /\A\.\./ || is_absolute($rel);
  return $scope eq 'user' ? '~/'.$rel : $rel;
}

# `s` as one shell word: as is when plain, else single-quoted; a leading `~/` stays unquoted.
sub _shell_word {
  my ( $s ) = @_;
  return '~/'._shell_word( substr $s, 2 ) if index( $s, '~/' ) == 0;
  return $s if $s =~ m{\A[\w./@%+=:,-]+\z}a;
  return "'".( $s =~ s/'/'\\''/gr )."'";
}

#### Loading #################################################################

# Config and targets as a sync needs them: no harness is a config error. A user-only operation
# passes false so a malformed project lock cannot affect it.
sub _load_strict {
  my ( $self, $include_project ) = @_;
  $include_project //= 1;
  my $config  = Skilletor::Config->load( home => $self->home, claude_config_dir => $self->claude_config_dir, project_dir => $self->project_dir_of );
  my $markers = $self->markers;
  my $wanted = { user => $config->user->{targets}, project => $config->project ? $config->project->{targets} : undef };
  if ( $include_project && $config->project && !exists $config->project->{targets} && defined $self->project_dir_of ) {
    my $target_dir = $self->_target_dir('project');
    my $lock_path = $self->_lock_path('project');
    my $in_use = grep { -e encode_text($_) } map { path_join( $target_dir, $_ ) } qw( skilletor.json skilletor.local.json skilletor.lock.json );
    $wanted->{project_evidence} = detect_project_harnesses( $self->project_dir_of, read_lock($lock_path) ) if $in_use;
  }
  my $targets = select_targets( $wanted, detect_harnesses($markers), $markers );
  return ( $config, $targets );
}

sub _scopes_of {
  my ( $config, $sel ) = @_;
  croak 'scope must be user, project or all' unless $sel =~ /\A(?:user|project|all)\z/;
  my @scopes;
  push @scopes, [ user => $config->user ] if $sel eq 'user' || $sel eq 'all';
  push @scopes, [ project => $config->project ] if ( $sel eq 'project' || $sel eq 'all' ) && $config->project;
  return @scopes;
}

# For a run Hermes started (spec §16.4): while `hermes` is no machine target – it is never
# detected, so until the user config's `targets` names it – the line that says how to opt in,
# naming the targets in use plus `hermes`. Undef when Hermes is a target, or when the config or
# the targets cannot be read (that error is reported on its own). Never dies.
sub hermes_opt_in_hint {
  my ( $self ) = @_;
  my ( $config, $targets );
  return undef unless eval { ( $config, $targets ) = $self->_load_strict(0); 1 };
  my @machine = @{ $targets->{user} };
  return undef if grep { $_ eq 'hermes' } @machine;
  my $wanted = join ', ', map {"\"$_\""} @machine, 'hermes';
  return 'Hermes gets no skills: "hermes" is not in "targets"; to opt in, set "targets": ['.$wanted.'] in ~/.claude/skilletor.json';
}

# The CLAUDE.md files Claude Code reads for a scope (spec §14.8).
sub _claude_memory_files {
  my ( $self, $scope ) = @_;
  return path_join( $self->claude_dir, 'CLAUDE.md' ) if $scope eq 'user';
  my $base = $self->_base_of($scope);
  return ( path_join( $base, 'CLAUDE.md' ), path_join( $base, '.claude', 'CLAUDE.md' ) );
}

#### Run notes and warnings (spec §14.8, §16.3) ##############################

my %HARNESS_LABEL = ( claude => 'Claude Code', codex => 'Codex', hermes => 'Hermes' );

# Why a harness has no place for the types it lacks, in a note's words.
my %NO_COUNTERPART = ( hermes => 'Hermes has no agent files and no rules directory' );

# Where a harness reads the copy of another, in a note's words.
my %SERVED_FROM = ( codex => '.agents/skills' );

# The run's notes (spec §16.3) of what an active harness got no copy of ({ harness, type, scope,
# via? } each): one line per harness for the types it has no counterpart of, one per harness and
# scope for what another harness's copy serves, each with a count per type.
sub _run_notes {
  my ( $no_copy ) = @_;
  my ( %groups, @order );
  for my $n (@$no_copy) {
    my $id = defined $n->{via} ? "$n->{harness} $n->{scope} $n->{via}" : $n->{harness};
    push @order, $id unless $groups{$id};
    $groups{$id} //= { first => $n, counts => {} };
    $groups{$id}{counts}{ $n->{type} }++;
  }
  return map {
    my ( $first, $counts ) = @{ $groups{$_} }{qw( first counts )};
    my $label = $HARNESS_LABEL{ $first->{harness} };
    my $what  = join ' and ', map { $counts->{$_}.' '.$_.'(s)' } grep { $counts->{$_} } qw( skill agent rule );
    defined $first->{via}
      ? $what.' not installed for '.$label.' in the '.$first->{scope}.' scope ('.$label.' reads the '.$HARNESS_LABEL{ $first->{via} }
        .' copy in '.( $SERVED_FROM{ $first->{via} } // 'its own root' ).')'
      : $what.' not installed for '.$label.' ('.( $NO_COUNTERPART{ $first->{harness} } // $label.' has no counterpart' ).')';
  } @order;
}

# Codex skips plugin hooks the user has not trusted, silently (spec §14.8): when Codex is a
# machine target and its config.toml has no trusted SessionStart hook for skilletor, one warning.
sub _hook_trust_warning {
  my ( $self, $targets ) = @_;
  return undef unless grep { $_ eq 'codex' } @{ $targets->{user} };
  my $codex_home = $self->_codex_home_of // path_join( $self->home, '.codex' );
  return undef if codex_hook_trusted($codex_home);
  return q{Codex has not trusted skilletor's SessionStart hook (no trusted_hash for it in }.path_join( $codex_home, 'config.toml' ).'); '
    .'until you trust it with /hooks in Codex, Codex sessions get no syncs and no rules';
}

#### Render inputs (spec §5, §14.3, k76) #####################################

sub _render_inputs_of {
  my ( $self, $scope, $scope_cfg ) = @_;
  return { vars => $scope_cfg->{vars} } unless $scope eq 'project';
  my $dir = $self->project_dir_of;
  ( my $name = $dir ) =~ s{\A.*/}{};
  return { vars => $scope_cfg->{vars}, project => { dir => $dir, name => $name, git_remote => $self->git_remote->($dir) } };
}

# The value as JSON with every object's keys sorted: key order in a config file is no change.
sub _canonical_json {
  my ( $v ) = @_;
  my $type = js_type($v);
  return '['.join( ',', map { _canonical_json($_) } @$v ).']' if $type eq 'array';
  if ( $type eq 'object' ) {
    return '{'.join( ',', map { js_stringify("$_").':'._canonical_json( $v->{$_} ) } js_sort_keys( keys %$v ) ).'}';
  }
  return js_stringify($v);
}

sub _render_inputs_hash {
  my ( $inputs ) = @_;
  return hash_bytes( encode_text( _canonical_json( { format => 0 + RENDER_FORMAT, %$inputs } ) ) );
}

# The template context of one copy (spec §5): the item's vars (source defaults < bundle vars <
# the scope's), the project, the scope, the harness and the root it is rendered for, host, user,
# the item. Deliberately no env.* and no git branch.
sub _render_context {
  my ( $self, $inputs, $scope, $harness, $target_dir, $item, $source_vars, $bundle_vars ) = @_;
  my $p = $inputs->{project};
  return {
    vars    => Skilletor::Resolver::_item_vars( $source_vars, $bundle_vars, $inputs->{vars} ),
    project => $p ? js_ordered( dir => $p->{dir}, name => $p->{name}, git_remote => $p->{git_remote} ) : undef,
    scope   => $scope,
    harness => $harness,
    target  => js_ordered( dir => $target_dir ),
    host    => $self->host,
    user    => $self->user,
    item    => js_ordered( name => $item->{name}, type => $item->{type}, source => $item->{source} ),
  };
}

sub _scope_sources {
  my ( $scope_cfg ) = @_;
  return _uniq( map { $_->{source} } @{ $scope_cfg->{install} }, @{ $scope_cfg->{wildcards} }, @{ $scope_cfg->{bundles} } );
}

# The sources a scope renders items from: those it declares, and those its lock holds entries of.
sub _render_sources {
  my ( $scope_cfg, $lock ) = @_;
  return _uniq( _scope_sources($scope_cfg), map { $lock->{$_}{source} } keys %$lock );
}

sub _source_read {
  my ( $backend, $version ) = @_;
  my $read = { kind => $backend->{kind}, address => $backend->{address}, version => $version };
  $read->{ref}  = $backend->{ref}  if defined $backend->{ref};
  $read->{path} = $backend->{path} if defined $backend->{path};
  return $read;
}

sub _source_version {
  my ( $lock, $name ) = @_;
  for my $e ( values %$lock ) { return $e->{version} if defined $e->{source} && $e->{source} eq $name }
  return undef;
}

# The version `check` compares a source with: the one the last sync read through this very
# backend (kind, address, ref, path); with no record, the lock's.
sub _checked_version {
  my ( $read, $backend, $lock, $name ) = @_;
  return _source_version( $lock, $name ) unless $read;
  my $same = $read->{kind} eq $backend->{kind} && $read->{address} eq $backend->{address}
    && ( $read->{ref} // "\0" ) eq ( $backend->{ref} // "\0" )
    && js_stringify( $read->{path} ) eq js_stringify( $backend->{path} );
  return $same ? $read->{version} : undef;
}

#### sync ####################################################################

sub sync {
  my ( $self, %opts ) = @_;
  my $sel = $opts{scope} // 'all';
  my $state = Skilletor::State->new( root => $self->state_root, read_once => 1 );
  my $report = $state->with_lock(
    sub {
      Skilletor::Source::Url->sweep_cache( $self->cache_root );
      Skilletor::Source::Git->sweep_cache( $self->cache_root );
      # Once the lock is held: another run this one waited for may have left nothing to do.
      if ( $opts{if_changed} ) {
        my $chk = $self->check( scope => $sel, local => 1 );
        return js_ordered( scopes => [] ) if !$chk->{changed} && !( defined $chk->{error} && length $chk->{error} );    # an error: the sync reports it
      }
      my ( $config, $targets );
      return js_ordered( scopes => [], error => _message($@) )
        unless eval { ( $config, $targets ) = $self->_load_strict( $sel ne 'user' ); 1 };
      my @scopes = _scopes_of( $config, $sel );
      my $run = {};
      my $no_copy = [];    # what an active harness got no copy of, named once per run
      my $out = js_ordered( scopes => [] );
      for my $s (@scopes) {
        my ( $scope, $scope_cfg ) = @$s;
        if ( $scope eq 'project' && $targets->{project_unresolved} ) {
          my $rep = empty_scope_report('project');
          push @{ $rep->{warnings} }, @{ $targets->{warnings} };
          push @{ $out->{scopes} }, $rep;
          next;
        }
        my $rep = $self->_sync_scope( $config, $scope_cfg, $scope, $targets->{$scope}, \%opts, $state, $run, $no_copy );
        # The record lives while Hermes is a target (spec §16.2); its entries went with it.
        $state->put_hermes_home(undef) if $scope eq 'user' && !grep { $_ eq 'hermes' } @{ $targets->{user} };
        unshift @{ $rep->{warnings} }, @{ $targets->{warnings} } if $scope eq 'project';
        push @{ $out->{scopes} }, $rep;
      }
      my $trust = $self->_hook_trust_warning($targets);
      $out->{warnings} = [$trust] if defined $trust;
      my @notes = _run_notes($no_copy);
      $out->{notes} = \@notes if @notes;
      return $out;
    },
    timeout_ms => $opts{lock_timeout_ms} // $self->lock_timeout_ms,
  );
  return $report;
}

# A sync that stops with an error may have changed the lock (a partial entry): the scope's
# records no longer hold and are cleared, so `check` counts everything again.
sub _sync_scope {
  my ( $self, @args ) = @_;
  my $rep;
  return $rep if eval { $rep = $self->_sync_scope_run(@args); 1 };
  my $err = $@;
  my ( $scope, $state ) = @args[ 2, 5 ];
  eval {
    my $lock_path = $self->_lock_path($scope);
    $state->put_unreached( $lock_path, [] );
    $state->put_sources_read( $lock_path, {} );
    $state->put_render_inputs( $lock_path, undef );
    1;
  };
  die $err;
}

sub _sync_scope_run {
  my ( $self, $config, $scope_cfg, $scope, $harnesses, $opts, $state, $run, $no_copy ) = @_;
  my $target_dir = $self->_target_dir($scope);
  my $base       = $self->_base_of($scope);
  my $rc         = $self->_root_context($scope);
  # Hermes no target: its entries go as an inactive target's, from the home they were synced under.
  $rc->{hermes_home} = $self->_recorded_hermes_home if $scope eq 'user' && !grep { $_ eq 'hermes' } @$harnesses;
  my $lock_path = path_join( $target_dir, 'skilletor.lock.json' );
  my @move_warnings;
  $self->_move_hermes_home( $state, $target_dir, $rc, $harnesses, \@move_warnings ) if $scope eq 'user';
  my $old_lock   = read_lock($lock_path);
  my $gitignore_on = $scope_cfg->{gitignore} ? 1 : 0;
  my $inputs;
  my $inputs_of = sub { $inputs //= $self->_render_inputs_of( $scope, $scope_cfg ) };

  my @plan;
  # Entries this version cannot place (an unknown harness prefix) are never touched.
  my @keep = grep { !defined root_of_key( $rc, $_ ) } keys %$old_lock;
  my %key_info;
  my $receivers_of = sub { @{ receivers( $harnesses, $_[0], $scope ) } };
  my $hooks = {
    keep => sub {
      my ( $target, $type ) = @_;
      for my $h ( $receivers_of->($type) ) {
        my $key = lock_key( $h, $target );
        push @keep, $key if exists $old_lock->{$key};
      }
    },
    declare => sub {
      my ( $item ) = @_;
      my @targets = $receivers_of->( $item->{type} );
      for my $h (@$harnesses) {
        next if grep { $_ eq $h } @targets;
        my $via = served_via( $harnesses, $h, $item->{type}, $scope );
        push @$no_copy, { harness => $h, type => $item->{type}, scope => $scope, ( defined $via ? ( via => $via ) : () ) };
      }
      return 0 unless @targets;
      for my $h (@targets) {
        my $key = lock_key( $h, $item->{target} );
        $key_info{$key} = js_ordered( key => $key, type => $item->{type}, name => $item->{name}, source => $item->{source} );
      }
      return 1;
    },
    build => sub {
      my ( $item, $extra, $found, $warnings ) = @_;
      my ( $r, $cat, $ci ) = @{$found}{qw( r cat item )};
      # Rendered once per target, with that target's harness and root (spec §14.3).
      for my $h ( $receivers_of->( $item->{type} ) ) {
        my $key = lock_key( $h, $item->{target} );
        my ( $output, $executable );
        my $ok = eval {
          $output = build( $ci, $r->{dir}, sub {
            $self->_render_context( $inputs_of->(), $scope, $h, root_of( $rc, $h, $item->{type} ), $item,
              $cat->{meta}{vars}, $extra->{bundleVars} );
          } );
          # A skill's scripts keep their source's executable bit (k99); an agent or rule never.
          $executable = $item->{type} eq 'skill' ? executables( $ci, $r->{dir} ) : {};
          1;
        };
        unless ($ok) {
          my $where = @$harnesses > 1 ? ' ('.$h.')' : '';
          push @$warnings, 'template error in '.$item->{type}.' '.$item->{name}.$where.': '._message($@);
          push @keep, $key if exists $old_lock->{$key};
          next;
        }
        my $p = { key => $key, type => $item->{type}, name => $item->{name}, source => $item->{source}, version => $r->{version} };
        $p->{via} = $extra->{via} if $extra->{via} && @{ $extra->{via} };
        $p->{inBlock} = 1 if is_block_type( $h, $item->{type} );
        # Main template renders empty: not applicable here (spec §5).
        if ( renders_empty( $ci, $output ) ) {
          $p->{output}  = [];
          $p->{skipped} = 'renders-empty';
          push @plan, $p;
          next;
        }
        # Per-target output mapping (spec §14.7): a Codex agent becomes TOML, a Codex rule a
        # section of the rules file. A conversion error leaves the target's copy as it was.
        my $conv = eval { convert_for_target( $h, $item->{type}, $item->{name}, $output ) };
        unless ($conv) {
          push @$warnings, $item->{type}.' '.$item->{name}.' ('.$h.'): '._message($@);
          push @keep, $key if exists $old_lock->{$key};
          next;
        }
        push @$warnings, map { $item->{type}.' '.$item->{name}.' ('.$h.'): '.$_ } @{ $conv->{warnings} };
        $p->{output} = $conv->{output};
        if ( $conv->{skipped} ) {
          $p->{skipped} = 'renders-empty';
          push @plan, $p;
          next;
        }
        $output = $p->{output};
        # Layout names (spec §6.3, §6.4): `.local.` agents and rules claiming their plain path; a
        # skill carries its own `.gitignore` while the scope's switch is on.
        my $placed = place_output( $h, $item->{type}, $output );
        $p->{output} = $placed->{output};
        $p->{claims} = $placed->{claims} if @{ $placed->{claims} };
        if ( $item->{type} eq 'skill' && $gitignore_on ) {
          $p->{output} = with_skill_gitignore( $p->{output}, $item->{name} );
          delete $executable->{ skill_gitignore_path( $item->{name} ) };    # skilletor's own, not the source's
        }
        $p->{executable} = $executable if %$executable;
        push @plan, $p;
      }
    },
  };

  my ( $rep, $info ) = $self->_resolve_scope( $config, $scope_cfg, $scope, $state, $run, $hooks );
  undef $hooks;
  # Past its deadline (spec §8): this scope's apply does not begin. Earlier scopes may already
  # have completed; from here on the scope's remaining work is local.
  die "sync stopped before applying the $scope scope: its sources took too long\n"
    if defined $opts->{deadline} && _now_ms() > $opts->{deadline};
  my $out = empty_scope_report($scope);
  $out->{warnings}      = [ @move_warnings, @{ $rep->{warnings} } ];
  $out->{trustRequests} = $rep->{trustRequests};
  my $warnings = $out->{warnings};
  my $label_of = sub {
    my ( $abs ) = @_;
    my $rel = _relative( $base, $abs );
    return ( $rel =~ /\A\.\./ || is_absolute($rel) ) ? $abs : to_posix($rel);
  };

  my $result = apply(
    \@plan,
    target_dir => $target_dir,
    force      => $opts->{force},
    keep       => \@keep,
    root_of    => sub { root_of_key( $rc, $_[0] ) // $target_dir },
  );

  # Codex rules (spec §14.8): the rules file and the AGENTS.md pointer, from the new lock.
  my $rules = ( grep { $_->{block} } values %$old_lock ) || ( grep { $_->{inBlock} } @plan )
      || -e encode_text( path_join( root_of( $rc, 'codex', 'rule' ), RULES_FILE ) )
    ? $self->_sync_codex_rules(
      scope => $scope, harnesses => $harnesses, rc => $rc, old_lock => $old_lock, plan => \@plan,
      lock_path => $lock_path, label_of => $label_of, warnings => $warnings,
    )
    : { overwritten => [], exists => 0, written => 0 };

  {
    # One block of fixed entries per target root (spec §6.4): `.claude/.gitignore` while the
    # scope is in use; a block found in another root goes. User roots get one only inside a git
    # work tree.
    my $new_lock   = read_lock($lock_path);
    my $in_use     = $scope eq 'user' || _project_in_use( $target_dir, $new_lock );
    my $codex_root = root_of( $rc, 'codex', 'rule' );
    my $holds_managed = sub {
      my ( $root ) = @_;
      return grep {
        my $e = $new_lock->{$_};
        !$e->{block} && %{ $e->{files} // {} } && ( root_of_key( $rc, $_ ) // '' ) eq $root;
      } keys %$new_lock;
    };
    for my $root ( all_roots($rc) ) {
      my @entries;
      if ( $in_use && $root eq $target_dir ) {
        @entries = $scope eq 'project' ? PROJECT_CLAUDE_ENTRIES : $self->_user_claude_entries($target_dir);
      }
      elsif ( $in_use && $root eq $codex_root && ( $rules->{exists} || $holds_managed->($root) ) ) {
        @entries = CODEX_ENTRIES;
      }
      my $enabled = $gitignore_on && @entries && ( $scope eq 'project' || $self->_in_work_tree($root) );
      my $change = update_gitignore( dir => $root, entries => \@entries, enabled => $enabled );
      push @{ $out->{gitignoreUpdated} }, _scope_label( $scope, $base, path_join( $root, '.gitignore' ) )
        if $change eq 'created' || $change eq 'changed';
    }
    # The project's `.worktreeinclude` (spec §6.4, k124), written while the project is in use.
    if ( $scope eq 'project' ) {
      my $change;
      if ( eval { $change = update_worktree_include( dir => $base, entries => [ $self->_worktree_include_entries($rc) ], enabled => $gitignore_on && $in_use ); 1 } ) {
        push @{ $out->{gitignoreUpdated} }, _scope_label( $scope, $base, path_join( $base, WORKTREE_INCLUDE ) )
          if $change eq 'created' || $change eq 'changed';
      }
      else {
        push @$warnings, WORKTREE_INCLUDE.' not updated: '._message($@);
      }
    }
  }

  # The plugin requirement in the committed `.claude/settings.json` (spec §6.8): add-only.
  my $final_lock = read_lock($lock_path);
  if ( my $settings = $self->_claude_settings_plan( $config, $scope, $harnesses, $final_lock ) ) {
    my $file  = $self->_settings_file;
    my $label = _scope_label( $scope, $base, $file );
    push @$warnings, @{ $settings->{warnings} };
    $out->{settingsSkipped} = [ @{ $settings->{warnings} } ] if @{ $settings->{warnings} };
    if ( defined $settings->{next} ) {
      if ( eval { write_text( $file, $settings->{next} ); 1 } ) {
        $out->{settingsUpdated} = js_ordered( path => $label, enabled => $settings->{enabled}, declared => $settings->{declared} );
      }
      else {
        push @$warnings, $label.' not updated: '._message($@);
      }
    }
  }

  # Managed paths git still tracks (spec §6.4): only what this run wrote or adopted.
  if ($gitignore_on) {
    my @written = map { { root => root_of_key( $rc, $_->{key} ) // $target_dir, key => $_->{key}, path => $_->{path} } } @{ $result->{written} };
    push @written, { root => root_of( $rc, 'codex', 'rule' ), path => RULES_FILE } if $rules->{written};
    push @$warnings, $self->_tracked_warnings( $scope, $base, \@written );
  }

  my $to_change = sub {
    my ( $key ) = @_;
    return $key_info{$key} if $key_info{$key};
    my $t = key_to_type_name($key);
    return js_ordered( key => $key, type => $t->{type}, name => $t->{name}, source => ( $info->{old_lock}{$key} || {} )->{source} // '?' );
  };
  $out->{$_} = [ map { $to_change->($_) } @{ $result->{$_} } ] for qw( added updated removed unchanged skipped );
  my $shown = sub {
    my ( $c ) = @_;
    my $root = root_of_key( $rc, $c->{key} ) // $target_dir;
    return $root eq $target_dir ? $c->{path} : $label_of->( path_join( $root, $c->{path} ) );
  };
  $out->{conflicts} = [
    map {
      my $c = js_ordered( path => $shown->($_) );
      $c->{replace} = $_->{replace} if $_->{replace};
      $c->{notFile} = $_->{notFile} if $_->{notFile};
      $c;
    } @{ $result->{conflicts} }
  ];
  $out->{overwritten} = [ ( map { js_ordered( path => $shown->($_) ) } @{ $result->{overwritten} } ), map { js_ordered( path => $_ ) } @{ $rules->{overwritten} } ];
  for my $l ( @{ $result->{leftInPlace} } ) {
    push @$warnings, $shown->($l).' is a symbolic link: files of '.$l->{key}.' behind it left in place (never deleted through a link)';
  }

  # Briefing check (spec §6.7): every agent the lock holds now, from its installed file.
  my @briefing = $self->_briefing_of( $scope, $final_lock );
  push @$warnings, briefing_warning( parse_lock_key( $_->{key} )->{name}, $_->{harness}, $_->{missing} ) for @briefing;
  $out->{briefingMissing} = \@briefing if @briefing;

  # The records `check` compares with (spec §14.3). A source counts as reached when it was
  # resolved and scanned: what a sync left in place although it read every source it needed – an
  # item its source lacks, a lasting conflict, a template error – is not counted again.
  my %resolved = %{ $info->{resolved} };
  my %catalogs = %{ $info->{catalogs} };
  my $reachable = sub {
    my ( $name ) = @_;
    return 0 unless $resolved{$name};
    return ( exists $catalogs{$name} && !defined $catalogs{$name} ) ? 0 : 1;
  };
  my @drift = $self->_scope_drift( $config, $scope, $harnesses, $final_lock, $info->{served} );
  $state->put_unreached( $lock_path, [ map { $_->{id} } grep { my $d = $_; !grep { !$reachable->($_) } @{ $d->{sources} } } @drift ] );
  my $before = $state->sources_read($lock_path);
  my %read;
  for my $name ( @{ $info->{resolved_order} } ) {
    my $r = $resolved{$name};
    if    ( $r && $reachable->($name) ) { $read{$name} = _source_read( $r->{backend}, $r->{version} ) }
    elsif ( $before->{$name} )          { $read{$name} = $before->{$name} }
  }
  $state->put_sources_read( $lock_path, \%read );
  my %untrusted = map { ( $_->{name} => 1 ) } @{ $out->{trustRequests} };
  if ( !_render_sources( $scope_cfg, $final_lock ) ) {
    $state->put_render_inputs( $lock_path, undef );
  }
  elsif ( !grep { !$reachable->($_) && !$untrusted{$_} } @{ $info->{resolved_order} } ) {
    $state->put_render_inputs( $lock_path, _render_inputs_hash( $inputs_of->() ) );
  }
  return $out;
}

# Rebuild a scope's Codex rules file from the new lock, then its AGENTS.md pointer (spec §14.8).
# Planned rules take their rendered section; kept ones (source unreachable) their text from the
# file – or, for an entry of the first design (#41, keyed `AGENTS.md`), from the old rules block
# in AGENTS.md, and the entry is rewritten under the new file name. A pointer refusal is a warning
# and touches neither the rules file nor the lock. Returns the overwritten local changes
# (`<file>#rules/<name>`), whether the rules file exists now, and whether this run wrote it.
sub _sync_codex_rules {
  my ( $self, %a ) = @_;
  my ( $scope, $rc, $old_lock, $label_of, $warnings ) = @a{qw( scope rc old_lock label_of warnings )};
  my $codex_root  = root_of( $rc, 'codex', 'rule' );
  my $rules_file  = path_join( $codex_root, RULES_FILE );
  my $rules_label = $label_of->($rules_file);
  my $agents_file = path_join( $scope eq 'user' ? $codex_root : $rc->{base}, 'AGENTS.md' );
  my $agents_label = $label_of->($agents_file);
  my $legacy_key  = 'AGENTS.md';    # the files key of a first-design entry

  my $file_text = eval { read_text($rules_file) };    # missing (or unreadable: rewritten below)
  my $current = defined $file_text ? parse_rules_file($file_text) : {};
  my $agents  = inspect_agents_md($agents_file);
  my $legacy  = $agents->{ok} && $agents->{parsed} ? $agents->{parsed}{sections} : undef;
  my %planned;
  for my $p ( grep { $_->{inBlock} && !$_->{skipped} } @{ $a{plan} } ) {
    my ($pair) = grep { $_->[0] eq RULES_FILE } @{ $p->{output} };
    $planned{ $p->{key} } = decode_utf8_lossy( $pair->[1] );
  }

  my $new_lock = read_lock( $a{lock_path} );
  my $migrated = 0;
  my ( %sections, @overwritten );
  for my $key ( keys %$new_lock ) {
    my $entry = $new_lock->{$key};
    next if !$entry->{block} || $entry->{skipped};
    my $name  = parse_lock_key($key)->{name};
    my $old   = $old_lock->{$key};
    my $old_files = $old ? $old->{files} // {} : {};
    my $prev_hash = $old && !$old->{skipped} ? $old_files->{ RULES_FILE() } : undef;
    my $on_disk = $current->{$name} // ( defined $old_files->{$legacy_key} && $legacy ? $legacy->{$name} : undef );
    my $files = $entry->{files} // {};
    if ( defined $files->{$legacy_key} && !defined $files->{ RULES_FILE() } ) {
      $entry->{files} = js_ordered( RULES_FILE() => $files->{$legacy_key} );    # kept first-design entry: same section, new file
      $migrated = 1;
    }
    my $text = $planned{$key} // ( $on_disk ? $on_disk->{text} : undef );
    next unless defined $text;
    # Edited or deleted by hand; a first-design entry (no hash for this file) moves silently.
    if ( defined $prev_hash && ( !$on_disk || hash_bytes( encode_text( $on_disk->{text} ) ) ne $prev_hash ) ) {
      push @overwritten, $rules_label.'#rules/'.$name;
    }
    $sections{$name} = { name => $name, source => $entry->{source}, text => $text };
  }
  write_lock( $a{lock_path}, $new_lock ) if $migrated;
  my @sections = map { $sections{$_} } js_sort_keys( keys %sections );

  my $next = rules_file_text( $scope, \@sections );
  my $exists  = defined $file_text ? 1 : 0;
  my $written = 0;
  my $ok = eval {
    if ( _differs( $next, $file_text ) ) {
      if ( defined $next ) { write_text( $rules_file, $next ) }
      else                 { unlink encode_text($rules_file) or $!{ENOENT} or die node_fs_error( 0 + $!, 'rm', $rules_file )."\n" }
      $written = defined $next ? 1 : 0;
    }
    $exists = defined $next ? 1 : 0;
    1;
  };
  push @$warnings, $rules_label.': cannot write the Codex rules file ('._message($@).')' unless $ok;

  # The pointer: present exactly when the rules file is.
  my $want  = $exists;
  my $state = $agents;
  # Claude Code reads CLAUDE.md: when that is this AGENTS.md, Claude would be sent to the Codex rules.
  my ($memory) = $want && grep( { $_ eq 'claude' } @{ $a{harnesses} } )
    ? grep { same_file( $_, $agents_file ) } $self->_claude_memory_files($scope)
    : ();
  $state = { ok => 0, reason => 'is the same file as '.$label_of->($memory).' (Claude Code would read it)' } if $state->{ok} && defined $memory;
  unless ( $state->{ok} ) {
    my $why = $state->{reason};
    if ( $want || index( $why, 'malformed' ) == 0 ) {
      push @$warnings, $agents_label.( index( $why, 'is ' ) == 0 ? ' ' : ': ' ).$why.'; pointer to the Codex rules not written';
    }
    return { overwritten => \@overwritten, exists => $exists, written => $written };
  }
  my $shown_rules = $scope eq 'user' ? $rules_file : '.codex/'.RULES_FILE;
  my $agents_next = with_block( $state->{text}, $want ? [ pointer_lines( $scope, $shown_rules ) ] : undef );
  if ( _differs( $agents_next, $state->{text} ) ) {
    if ( defined $agents_next ) { write_text( $agents_file, $agents_next ) }
    else                        { unlink encode_text($agents_file) or $!{ENOENT} or die node_fs_error( 0 + $!, 'rm', $agents_file )."\n" }
  }
  if ($want) {
    my $override = path_join( $scope eq 'user' ? $codex_root : $rc->{base}, 'AGENTS.override.md' );
    if ( -e encode_text($override) ) {
      push @$warnings, $label_of->($override).' exists; Codex reads it instead of AGENTS.md, so the pointer to the skilletor rules is not seen';
    }
    if ( $scope eq 'project' && defined $agents_next ) {
      my $limit = project_doc_limit( $self->_codex_home_of // path_join( $self->home, '.codex' ) );
      my $bytes = length encode_text($agents_next);
      if ( $bytes > $limit ) {
        push @$warnings, $agents_label.' is '.$bytes.' bytes; Codex reads at most '.$limit.' bytes of project instructions '
          .'(project_doc_max_bytes), so the pointer to the rules at its end may be cut off';
      }
    }
  }
  return { overwritten => \@overwritten, exists => $exists, written => $written };
}

sub _in_work_tree {
  my ( $self, $dir ) = @_;
  my $yes = eval { $self->is_git_work_tree->($dir) };
  return $yes ? 1 : 0;
}

# Entries of the user `~/.claude` block: the lock, the state dir when it lies under `~/.claude`,
# the agent and rule patterns. Never `skilletor.json`.
sub _user_claude_entries {
  my ( $self, $claude_dir ) = @_;
  my $rel = _relative( $claude_dir, $self->state_root );
  my $under = length $rel && $rel !~ /\A\.\./ && !is_absolute($rel);
  return ( 'skilletor.lock.json', ( $under ? $rel.'/' : () ), LOCAL_ENTRIES );
}

# Is the project scope in use: a project config file, or lock entries?
sub _project_in_use {
  my ( $target_dir, $lock ) = @_;
  return 1 if %$lock;
  return ( grep { -e encode_text( path_join( $target_dir, $_ ) ) } qw( skilletor.json skilletor.local.json ) ) ? 1 : 0;
}

# The `.worktreeinclude` block of a project (k124): every project root a harness's items go to,
# whether or not this machine targets it, the lock and the local config – fixed, sorted.
sub _worktree_include_entries {
  my ( $self, $rc ) = @_;
  my $at = sub { '/'.to_posix( _relative( $rc->{base}, $_[0] ) ).( $_[1] // '' ) };
  my $claude = path_join( $rc->{base}, '.claude' );
  my @out = ( $at->( path_join( $claude, 'skilletor.lock.json' ) ), $at->( path_join( $claude, 'skilletor.local.json' ) ) );
  for my $h (HARNESSES) {
    for my $type (ITEM_TYPES) {
      my $root = root_of( $rc, $h, $type ) // next;
      if    ( is_block_type( $h, $type ) ) { push @out, $at->( path_join( $root, RULES_FILE ) ) }
      elsif ( $type eq 'skill' )           { push @out, $at->( path_join( $root, 'skills' ), '/' ) }
      elsif ( is_local_type( $h, $type ) ) { push @out, $at->( path_join( $root, $type.'s' ), '/**/.local.*' ) }
    }
  }
  return js_sort_keys( _uniq(@out) );
}

sub _settings_file { my ( $self ) = @_; return path_join( $self->_target_dir('project'), 'settings.json' ) }

# What a sync adds to the project's `.claude/settings.json` (spec §6.8), or undef when the file is
# not skilletor's to touch. A proposed write must preserve implicit targets. $lock owns the files
# currently on disk (the new lock after apply, not the pre-sync lock). Never throws.
sub _claude_settings_plan {
  my ( $self, $config, $scope, $harnesses, $lock ) = @_;
  return undef unless $scope eq 'project';
  my $scope_cfg = $config->project;
  return undef if js_type( $scope_cfg->{claudeSettings} ) eq 'boolean' && !$scope_cfg->{claudeSettings};
  return undef unless grep { $_ eq 'claude' } @$harnesses;
  return undef unless -e encode_text( path_join( $self->_target_dir($scope), 'skilletor.json' ) );
  my $file  = $self->_settings_file;
  my $label = _scope_label( $scope, $self->project_dir_of, $file );
  my $plan  = eval {
    my $proposed = plan_claude_settings(
      file => $file, label => $label, project_dir => $self->project_dir_of,
      claude_dir => $self->claude_dir,
      plugin_root => ( defined $self->plugin_root && length $self->plugin_root ) ? $self->plugin_root : undef,
    );
    if ( defined $proposed->{next} && !exists $scope_cfg->{targets} ) {
      my $projected = select_targets(
        { user => $config->user->{targets}, project_evidence => detect_project_harnesses( $self->project_dir_of, $lock, $proposed->{next} ) },
        detect_harnesses( $self->markers ),
      );
      if ( $projected->{project_unresolved} || join( ',', @{ $projected->{project} } ) ne join( ',', @$harnesses ) ) {
        $proposed = { enabled => [], declared => [], warnings => [ @{ $proposed->{warnings} },
          $label.' not updated: the plugin requirement would change implicitly selected project targets; '
            .'set "targets" in the project\'s .claude/skilletor.json or .claude/skilletor.local.json, then sync',
        ] };
      }
    }
    $proposed;
  };
  return $plan // { enabled => [], declared => [], warnings => [ $label.' not updated: '._message($@) ] };
}

# The tracked-file warnings (spec §6.4): of the written and adopted paths, the ones git tracks –
# one warning per item with the command that untracks it.
sub _tracked_warnings {
  my ( $self, $scope, $base, $written ) = @_;
  my ( %by_root, @roots );
  for my $w (@$written) {
    push @roots, $w->{root} unless $by_root{ $w->{root} };
    push @{ $by_root{ $w->{root} } }, $w;
  }
  my @out;
  for my $root (@roots) {
    my $list = $by_root{$root};
    my $tracked = eval { $self->git_tracked->( $root, [ _uniq( map { $_->{path} } @$list ) ] ) } or next;
    my %tracked = map { ( $_ => 1 ) } @$tracked;
    my ( %items, @ids );
    for my $w (@$list) {
      next unless $tracked{ $w->{path} };
      my $id = $w->{key} // $w->{path};
      push @ids, $id unless $items{$id};
      $items{$id} //= { key => $w->{key}, paths => [] };
      push @{ $items{$id}{paths} }, $w->{path};
    }
    for my $id (@ids) {
      my ( $key, $paths ) = @{ $items{$id} }{qw( key paths )};
      my $k       = defined $key ? parse_lock_key($key) : undef;
      my $skill   = $k && $k->{type} eq 'skill';
      my @targets = $skill ? ( $k->{target} ) : @$paths;
      my $r       = $skill ? ' -r' : '';
      my $cmd = $scope eq 'project'
        ? 'git rm'.$r.' --cached '.join( ' ', map { _shell_word( _scope_label( $scope, $base, path_join( $root, $_ ) ) ) } @targets )
        : 'git -C '._shell_word( _scope_label( $scope, $base, $root ) ).' rm'.$r.' --cached '.join( ' ', map { _shell_word($_) } @targets );
      my $label = $key // _scope_label( $scope, $base, path_join( $root, $paths->[0] ) );
      push @out, $label.' is tracked by git although skilletor manages it — untrack it: '.$cmd;
    }
  }
  return @out;
}

# Installed agents of a scope's lock whose declared briefing skills do not resolve (spec §6.7).
sub _briefing_of {
  my ( $self, $scope, $lock, $only ) = @_;
  my $rc = $self->_root_context($scope);
  my $roots = { home => $self->home, claude_dir => $self->claude_dir, codex_home => $self->_codex_home_of, project_dir => $scope eq 'project' ? $self->project_dir_of : undef };
  my ( %roots_of, @out );
  for my $key ( keys %$lock ) {
    my $entry = $lock->{$key};
    my $k = parse_lock_key($key);
    next if !defined $k->{harness} || $k->{type} ne 'agent' || $entry->{skipped} || $entry->{block} || ( $only && !$only->{$key} );
    my $root = root_of_key( $rc, $key );
    my ($file) = keys %{ $entry->{files} // {} };
    next unless defined $root && defined $file;
    $roots_of{ $k->{harness} } //= skill_roots( $k->{harness}, $scope, $roots );
    my $missing = missing_skills( $k->{harness}, path_join( $root, $file ), $roots_of{ $k->{harness} } );
    push @out, js_ordered( key => $key, harness => $k->{harness}, missing => $missing ) if $missing && @$missing;
  }
  return @out;
}

#### Drift (spec §14.3) ######################################################

my $SKILL_GITIGNORE_HASH = hash_bytes( encode_text(SKILL_GITIGNORE) );

# Every drift of a scope: targets, layout, declarations, each { kind, id, sources }.
sub _scope_drift {
  my ( $self, $config, $scope, $harnesses, $lock, $served_by ) = @_;
  my $scope_cfg = $scope eq 'project' ? $config->project : $config->user;
  my @out;
  for my $g ( @{ target_gaps( [ keys %$lock ], $harnesses, $scope ) } ) {
    my $source = $lock->{ $g->{key} }{source};
    push @out, defined $g->{missing}
      ? { kind => 'targets', id => 'missing:'.$g->{missing}.'@'.( $source // 'undefined' ), sources => [$source] }
      : { kind => 'targets', id => 'orphan:'.$g->{key}, sources => [] };
  }
  # The run's Hermes home is not the one the user scope was last synced under (spec §16.2): a
  # sync moves the lock's Hermes entries there, or just records the home Hermes now uses.
  # (Hermes no target: its entries are orphans above.)
  if ( $scope eq 'user' && grep { $_ eq 'hermes' } @$harnesses ) {
    my $home = $self->_hermes_home_of;
    push @out, { kind => 'targets', id => 'hermes-home:'.$home, sources => [] } unless same_path( $home, $self->_recorded_hermes_home );
  }
  my $settings = $self->_claude_settings_plan( $config, $scope, $harnesses, $lock );
  push @out, { kind => 'layout', id => 'layout:claude-settings', sources => [] } if $settings && defined $settings->{next};
  return ( @out, $self->_layout_drift( $scope, $scope_cfg, $lock ), _declared_drift( $scope_cfg, $scope, $harnesses, $lock, $served_by ) );
}

# A user-scope sync under another Hermes home than the last (spec §16.2): the lock's Hermes
# entries are paths under the old home, so what it owns there is deleted and the entries are
# dropped – the sync then installs under the new home by the ordinary rules, and a file already
# there is never taken for skilletor's own. The new home is recorded before anything is
# installed under it: a sync that stops later leaves a lock and a record that agree. With Hermes
# no target nothing moves: the sync removes its entries from the recorded home as an inactive
# target's, and then drops the record.
sub _move_hermes_home {
  my ( $self, $state, $target_dir, $rc, $harnesses, $warnings ) = @_;
  return unless grep { $_ eq 'hermes' } @$harnesses;
  my $previous = $self->_recorded_hermes_home;
  my $current  = $self->_hermes_home_of;
  return if same_path( $previous, $current );
  my $lock  = read_lock( path_join( $target_dir, 'skilletor.lock.json' ) );
  my @moved = grep { ( parse_lock_key($_)->{harness} // '' ) eq 'hermes' } keys %$lock;
  if (@moved) {
    my %moved = map { ( $_ => 1 ) } @moved;
    my $old   = { %$rc, hermes_home => $previous };
    apply(
      [],
      target_dir => $target_dir,
      keep       => [ grep { !$moved{$_} } keys %$lock ],
      root_of    => sub { root_of_key( $old, $_[0] ) // $target_dir },
    );
    push @$warnings, 'Hermes home changed from '.$previous.' to '.$current.': '.scalar(@moved).' item(s) removed from the old home; '
      .'what is declared installs anew under the new one';
  }
  $state->put_hermes_home( same_path( $current, $self->_hermes_default ) ? undef : $current );
}

sub _layout_drift {
  my ( $self, $scope, $scope_cfg, $lock ) = @_;
  my $gitignore_on = $scope_cfg->{gitignore} ? 1 : 0;
  my @out;
  for my $key ( keys %$lock ) {
    my $entry = $lock->{$key};
    my $k     = parse_lock_key($key);
    my @files = keys %{ $entry->{files} // {} };
    next if !defined $k->{harness} || !supports( $k->{harness}, $k->{type} ) || $entry->{skipped} || $entry->{block} || !@files;
    my $drift = sub { push @out, { kind => 'layout', id => 'layout:'.$key.':'.$_[0], sources => [ $entry->{source} ] } };
    $drift->('local') if lacks_local_prefix( $k->{harness}, $k->{type}, \@files );
    if ( $k->{type} eq 'skill' ) {
      my $ours = ( $entry->{files}{ skill_gitignore_path( $k->{name} ) } // '' ) eq $SKILL_GITIGNORE_HASH ? 1 : 0;
      $drift->( $gitignore_on ? 'gitignore' : 'no-gitignore' ) if $ours != $gitignore_on;
    }
  }
  my $in_use = $scope eq 'project' && _project_in_use( $self->_target_dir($scope), $lock );
  if ( $scope eq 'project' && !$in_use && grep { has_block($_) } all_roots( $self->_root_context($scope) ) ) {
    push @out, { kind => 'layout', id => 'layout:unused-project', sources => [] };
  }
  if ( $scope eq 'project' ) {
    my $rc   = $self->_root_context($scope);
    my @want = $gitignore_on && $in_use ? $self->_worktree_include_entries($rc) : ();
    my @have = block_entries( path_join( $rc->{base}, WORKTREE_INCLUDE ) );
    if ( join( "\n", @have ) ne join( "\n", @want ) && ( @have || %$lock ) ) {
      push @out, { kind => 'layout', id => 'layout:worktreeinclude', sources => [] };
    }
  }
  return @out;
}

# The wildcards and bundles of a scope that declare a lock entry: a bundle its `via` names, a
# wildcard of its source and type whose pattern matches its name.
sub _cover_of {
  my ( $scope_cfg, $k, $entry ) = @_;
  return (
    ( grep { Skilletor::Resolver::_via_has( $entry->{via}, Skilletor::Resolver->bundle_label($_) ) } @{ $scope_cfg->{bundles} } ),
    ( grep { defined $entry->{source} && $_->{source} eq $entry->{source} && $_->{type} eq $k->{type} && matches_pattern( $_->{pattern}, $k->{name} ) }
        @{ $scope_cfg->{wildcards} } ),
  );
}

sub _declared_drift {
  my ( $scope_cfg, $scope, $harnesses, $lock, $served_by ) = @_;
  my @out;
  my $drift = sub { push @out, { kind => 'declared', id => $_[0], sources => $_[1] } };
  my %explicit;
  for my $item ( @{ $scope_cfg->{install} } ) {
    $explicit{ $item->{target} } = 1;
    for my $h ( @{ receivers( $harnesses, $item->{type}, $scope ) } ) {
      my $key = lock_key( $h, $item->{target} );
      my $have = $lock->{$key} ? $lock->{$key}{source} : undef;
      $drift->( 'missing:'.$key.'@'.$item->{source}, [ $item->{source} ] ) unless defined $have && $have eq $item->{source};
    }
  }
  my %covered;
  for my $key ( keys %$lock ) {
    my $entry = $lock->{$key};
    my $k = parse_lock_key($key);
    next unless defined $k->{harness} && grep { $_ eq $k->{harness} } @{ receivers( $harnesses, $k->{type}, $scope ) };
    my @by = _cover_of( $scope_cfg, $k, $entry );
    $covered{ refaddr $_ } = 1 for @by;
    $drift->( 'orphan:'.$key, [] ) if !@by && !$explicit{ $k->{target} };
    $drift->( 'partial:'.$key, [ $entry->{source} ] ) if $entry->{partial};    # a sync failed midway (k71)
  }
  for my $w ( @{ $scope_cfg->{wildcards} } ) {
    $drift->( 'wildcard:'.$w->{type}.':'.$w->{raw}, [ $w->{source} ] ) unless $covered{ refaddr $w };
  }
  for my $b ( @{ $scope_cfg->{bundles} } ) {
    my $label = Skilletor::Resolver->bundle_label($b);
    $drift->( $label, [ $b->{source}, @{ ( $served_by // {} )->{$label} // [] } ] ) unless $covered{ refaddr $b };
  }
  return @out;
}

#### check ###################################################################

sub check {
  my ( $self, %opts ) = @_;
  my $sel = $opts{scope} // 'all';
  my ( $config, $targets );
  unless ( eval { ( $config, $targets ) = $self->_load_strict( $sel ne 'user' ); 1 } ) {
    return js_ordered( changed => _false, sources => [], warnings => [], error => _message($@) );
  }
  my @scopes = _scopes_of( $config, $sel );
  my $state = Skilletor::State->new( root => $self->state_root, read_once => 1 );    # it only reads
  my $out = js_ordered( changed => _false, sources => [], warnings => [] );
  my %field = ( targets => 'targetsChanged', layout => 'layoutChanged', declared => 'declaredChanged' );
  push @{ $out->{warnings} }, @{ $targets->{warnings} }
    if $targets->{project_unresolved} && grep { $_->[0] eq 'project' } @scopes;

  for my $s (@scopes) {
    my ( $scope, $scope_cfg ) = @$s;
    next if $scope eq 'project' && $targets->{project_unresolved};
    my $lock_path = $self->_lock_path($scope);
    my $old_lock  = read_lock($lock_path);
    my %trust;
    my $trusted = sub {
      my ( $name ) = @_;
      $trust{$name} //= do {
        my $src = $config->source_of( $scope, $name );
        ( $src && eval { $state->is_trusted( $name, Skilletor::Backend->resolve( $src, $self->home ) ) } ) ? 1 : 0;
      };
      return $trust{$name};
    };
    # Drift counts unless the last sync tried it with its sources at hand, or a source it needs
    # is untrusted – that asks for trust, not for a sync.
    my %unreached = map { ( $_ => 1 ) } @{ $state->unreached($lock_path) };
    my $read = $state->sources_read($lock_path);
    my @open = grep {
      my $d = $_;
      !$unreached{ $d->{id} } && !grep { !$trusted->($_) } @{ $d->{sources} };
    } $self->_scope_drift( $config, $scope, $targets->{$scope}, $old_lock );
    for my $kind (qw( targets layout declared )) {
      next unless grep { $_->{kind} eq $kind } @open;
      $out->{changed} = _true;
      push @{ $out->{ $field{$kind} } }, $scope;
    }
    # What the last sync rendered with (k76), while a trusted source has items to render.
    if ( ( grep { $trusted->($_) } _render_sources( $scope_cfg, $old_lock ) )
      && ( $state->render_inputs($lock_path) // '' ) ne _render_inputs_hash( $self->_render_inputs_of( $scope, $scope_cfg ) ) )
    {
      $out->{changed} = _true;
      push @{ $out->{varsChanged} }, $scope;
    }
    # Sources a bundle pulled items from (spec §15.6) are not declared here; the lock names them.
    my @via_sources = map { $old_lock->{$_}{source} } grep { my $v = $old_lock->{$_}{via}; ref $v eq 'ARRAY' ? @$v : ( defined $v && length $v ) } keys %$old_lock;
    for my $name ( _uniq( _scope_sources($scope_cfg), @via_sources ) ) {
      my $src = $config->source_of( $scope, $name ) or next;
      my $ok = eval {
        my $backend = Skilletor::Backend->resolve( $src, $self->home );
        if ( !$state->is_trusted( $name, $backend ) ) {
          # Named in every check, as a sync names it (spec §4.3); never fetched.
          my $t = Skilletor::Backend->trust_request( $name, $backend );
          push @{ $out->{trustRequests} }, js_ordered( scope => $scope, map { ( $_ => $t->{$_} ) } keys %$t );
          return 1;
        }
        return 1 if $opts{local};    # the lock against the config only: no source asked
        my $version = _checked_version( $read->{$name}, $backend, $old_lock, $name );
        my $changed = Skilletor::Backend->make( $backend, $self->cache_root, $self->timeout_ms )->check($version) ? 1 : 0;
        push @{ $out->{sources} }, js_ordered( name => $name, scope => $scope, changed => $changed ? _true : _false );
        $out->{changed} = _true if $changed;
        1;
      };
      push @{ $out->{warnings} }, 'source '.$name.': '._message($@) unless $ok;
    }
  }
  return $out;
}

#### status ##################################################################

sub status {
  my ( $self, %opts ) = @_;
  my $sel = $opts{scope} // 'all';
  my ( $config, $targets );
  return js_ordered( scopes => [], error => _message($@) )
    unless eval { ( $config, $targets ) = $self->_load_strict( $sel ne 'user' ); 1 };
  my @scopes = _scopes_of( $config, $sel );
  my $state = Skilletor::State->new( root => $self->state_root );
  my $out = js_ordered( scopes => [] );
  $out->{warnings} = [ @{ $targets->{warnings} } ]
    if $targets->{project_unresolved} && grep { $_->[0] eq 'project' } @scopes;
  my $given = $self->project_dir;
  $out->{projectIsHome} = _true if $sel ne 'user' && defined $given && length $given && !defined $self->project_dir_of;

  for my $s (@scopes) {
    my ( $scope, $scope_cfg ) = @$s;
    my $lock   = read_lock( $self->_lock_path($scope) );
    my $active = $targets->{$scope};
    # One row per declared item and active target that gets a copy of its type.
    my @rows = map {
      my $i = $_;
      map { { key => lock_key( $_, $i->{target} ), source => $i->{source} } } @{ receivers( $active, $i->{type}, $scope ) };
    } @{ $scope_cfg->{install} };
    my %declared_keys = map { ( $_->{key} => 1 ) } @rows;
    my $versions = js_ordered();
    $versions->{ $lock->{$_}{source} } = $lock->{$_}{version} for grep { defined $lock->{$_}{source} } keys %$lock;
    my @trust;
    for my $name ( _scope_sources($scope_cfg) ) {
      my $src = $config->source_of( $scope, $name ) or next;
      my $backend = Skilletor::Backend->resolve( $src, $self->home );
      push @trust, Skilletor::Backend->trust_request( $name, $backend ) unless $state->is_trusted( $name, $backend );
    }
    # A skip entry is declared but deliberately not installed.
    my @declared = map {
      my $entry = $lock->{ $_->{key} };
      my $d = js_ordered( key => $_->{key}, source => $_->{source}, installed => ( $entry && !$entry->{skipped} ) ? _true : _false );
      $d->{skipped} = $entry->{skipped} if $entry && $entry->{skipped};
      $d->{partial} = _true if $entry && $entry->{partial};
      $d;
    } @rows;
    my ( %via, @orphans );    # distinct item targets per covering entry
    for my $key ( keys %$lock ) {
      next if $declared_keys{$key};
      my $entry = $lock->{$key};
      my $k = parse_lock_key($key);
      my @covering = ( defined $k->{harness} && grep { $_ eq $k->{harness} } @$active ) ? _cover_of( $scope_cfg, $k, $entry ) : ();
      my $first = $covering[0];
      unless ($first) {
        push @orphans, $key;
        next;
      }
      my $label = exists $first->{pattern} ? $first->{raw} : Skilletor::Resolver->bundle_label($first);
      if ( $entry->{skipped} ) {
        push @declared, js_ordered( key => $key, source => $entry->{source}, installed => _false, via => $label, skipped => $entry->{skipped} );
        next;
      }
      my $d = js_ordered( key => $key, source => $entry->{source}, installed => _true, via => $label );
      $d->{partial} = _true if $entry->{partial};
      push @declared, $d;
      $via{ refaddr $_ }{ $k->{target} } = 1 for @covering;
    }
    my %installed = map { ( $_->{key} => 1 ) } grep { $_->{installed} } @declared;
    my %missing = map { ( $_->{key} => $_->{missing} ) } $self->_briefing_of( $scope, $lock, \%installed );
    $_->{briefingMissing} = $missing{ $_->{key} } for grep { $missing{ $_->{key} } } @declared;
    my $installed_via = sub { 0 + keys %{ $via{ refaddr $_[0] } // {} } };
    push @{ $out->{scopes} }, js_ordered(
      scope     => $scope,
      targets   => [@$active],
      declared  => \@declared,
      orphans   => \@orphans,
      wildcards => [ map { js_ordered( type => $_->{type}, source => $_->{source}, entry => $_->{raw}, installed => $installed_via->($_) ) }
          @{ $scope_cfg->{wildcards} } ],
      bundles => [ map { js_ordered( name => $_->{name}, source => $_->{source}, entry => $_->{raw}, installed => $installed_via->($_) ) }
          @{ $scope_cfg->{bundles} } ],
      trustRequests  => \@trust,
      sourceVersions => $versions,
    );
  }
  my $trust = $self->_hook_trust_warning($targets);
  push @{ $out->{warnings} //= [] }, $trust if defined $trust;
  return $out;
}

#### The Codex rules context (spec §14.8) #####################################

# The Codex rules files the SessionStart hook injects: the user scope's, then the project's, each
# when it exists and Codex is a target of that scope. When the config or the targets cannot be
# loaded, every existing file (the last good state). Reads no source and never throws.
sub codex_rules_files {
  my ( $self ) = @_;
  my ( $config, $targets );
  my $loaded = eval { ( $config, $targets ) = $self->_load_strict; 1 };
  my @out;
  for my $scope ( 'user', ( defined $self->project_dir_of ? 'project' : () ) ) {
    next if $loaded && !grep { $_ eq 'codex' } @{ $targets->{$scope} };
    my $file = path_join( root_of( $self->_root_context($scope), 'codex', 'rule' ), RULES_FILE );
    push @out, $file if -e encode_text($file);
  }
  return @out;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Skilletor::Engine - sync, check and status for Claude Code, Codex and Hermes – the reference's engine pipeline after the resolve

=head1 VERSION

version 0.008000

=head1 SYNOPSIS

  use Skilletor::Engine;

  my $engine = Skilletor::Engine->new( home => $ENV{HOME}, project_dir => $project );

  my $report = $engine->sync( scope => 'all', force => 0 );   # what `skilletor sync --json` prints
  my $check  = $engine->check( scope => 'all' );              # `skilletor check --json`
  my $status = $engine->status( scope => 'all' );             # `skilletor status --json`

=head1 DESCRIPTION

The reference's engine (C<engine.ts>) after the resolve: C<sync>, C<check>
and C<status> for Claude Code, Codex and Hermes. It extends L<Skilletor::Resolver> – a sync runs
the very resolve that class reports, then builds every declared item in memory,
applies it (L<Skilletor::Apply>), writes the managed blocks
(L<Skilletor::Gitignore>) and the project's plugin requirement
(L<Skilletor::ClaudeSettings>), runs the briefing check
(L<Skilletor::Briefing>) and keeps the records C<check> compares with
(L<Skilletor::State>). Most callers want L<Skilletor/sync>.

What it writes is the reference's, byte for byte – installed files with their
executable bits, the lock, the C<.gitignore> blocks, C<.worktreeinclude>,
C<.claude/settings.json> – and the reports are the reference's C<SyncReport>,
C<CheckReport> and C<StatusReport>, field for field, booleans as
L<JSON::MaybeXS> booleans, every object's keys in the order the reference
builds them (hashes from L<Skilletor::JSON/js_ordered>), so
L<Skilletor::Report/report_json> prints the bytes C<--json> prints. The state
records (C<render-inputs.json> with the same C<RENDER_FORMAT>,
C<sources-read.json>, C<unreached.json>) are the same bytes too, so a C<check>
of either implementation accepts what the other synced: the shared conformance
cases, F<t/52-parity-sync.t> and F<t/65-report-json.t> hold both to that. Like
the reference, a sync holds the sync lock (L<Skilletor::State/with_lock>);
C<check> and C<status> read without it.

=head2 Claude Code, Codex and Hermes

The port installs for Claude Code, Codex and Hermes, as the reference does (spec
§14). For Codex: the skills of both scopes in C<.agents/skills>, each
agent converted to Codex's TOML (L<Skilletor::Convert>), the rules as
sections of one C<skilletor-rules.md> under C<$CODEX_HOME> or the project's
C<.codex>, with a pointer block in the scope's C<AGENTS.md>
(L<Skilletor::AgentsMD>). The pointer is refused – a warning, nothing written
– when that C<AGENTS.md> is a link, malformed, or the very file Claude Code
reads as C<CLAUDE.md>; an C<AGENTS.override.md> beside it and a project
C<AGENTS.md> over C<project_doc_max_bytes> are warnings. A sync's report
carries the run's C<notes> (the items an active harness gets no copy of) and,
like C<status>, the run's C<warnings> (Codex has not trusted skilletor's
SessionStart hook). The SessionStart hook injects the rules files
(L</codex_rules_files>).

Hermes gets skills only (spec §16), and only while the user config's
C<targets> names it – it is never detected. Its user root is the Hermes home's
C<skills> (L</hermes_home>), its project root the project's C<.hermes/skills>,
which gets no managed C<.gitignore> block; in a project where Codex is a target
too, Hermes reads the Codex copy in C<.agents/skills> and gets none of its own.
The user scope records the Hermes home it synced under in the state dir
(L<Skilletor::State/hermes_home>): a sync under another home removes the lock's
Hermes entries from the old one, with a warning, and installs them anew under
the new one, and C<check> counts the move as C<targetsChanged>; once Hermes is
no target, a sync removes its entries from the recorded home and drops the
record. What Hermes gets no copy of – agents and rules, project skills Codex
serves – is a sync's C<notes>. L</hermes_opt_in_hint> words how to opt in.
Lock entries of a harness neither implementation knows are kept untouched, as
the reference keeps them.

=head2 Templates

A declared item with a C<.njk> file is rendered as the reference renders it
(L<Skilletor::Render>), once per target, with the reference's context: the
item's C<vars> (source defaults, bundle vars, the scope's), C<project> (in the
project scope), C<scope>, C<harness>, C<target> (the root the copy goes to),
C<host> (L</host>), C<user> (L</user>) and C<item>. A template that fails is a
warning (C<< template error in skill greet: skills/greet/SKILL.md.njk: … >>,
the reference's) and leaves the item as it is installed, files and lock entry;
its source still counts as read. An item whose main template renders to
whitespace once its frontmatter is removed does not apply in the scope: it is
skipped (C<renders-empty>), what it installed is removed, and its lock entry
says why.

=head2 Errors

A config error, or no agent harness, is the report's C<error> (the reference's
message); nothing is touched. Like the reference, a sync that fails while it
writes (L<Skilletor::Error::Apply>, a file system error) throws: what landed is
owned by the lock, its entries marked C<partial>, and the scope's records are
cleared so C<check> asks for the retry. An unreadable lock throws
L<Skilletor::Error::Lock>, a sync lock held too long
L<Skilletor::Error::LockTimeout>.

=head2 is_git_work_tree

  is_git_work_tree => sub { my ( $dir ) = @_; ... }

Does a user-scope root lie inside a git work tree (spec §6.4)? Default: ask
git (L<Skilletor::Gitignore/is_git_work_tree>). A user root gets a
C<.gitignore> block only inside one.

=head2 git_tracked

  git_tracked => sub { my ( $dir, $paths ) = @_; return [ ...tracked... ] }

Which of the written paths does git track? Default: one C<git ls-files>
(L<Skilletor::Gitignore/git_tracked>). Each tracked item is a warning with the
command that untracks it.

=head2 git_remote

  git_remote => sub { my ( $project_dir ) = @_; return $url }

The project's C<origin>, a render input of the project scope. Default: ask git.

=head2 hermes_home

C<$HERMES_HOME> (spec §16.2), by default from the environment: the Hermes home
whose C<skills> is the user scope's Hermes root – the Hermes plugin passes its
session's. A leading C<~> is the L<Skilletor::Resolver/home>. Unset or empty:
the home the last user-scope sync recorded, else Hermes' default
(C<~/.hermes>; C<%LOCALAPPDATA%\hermes> on Windows), so a run no Hermes started
serves the same home as the Hermes session before it.

=head2 plugin_root

C<CLAUDE_PLUGIN_ROOT> by default: the running plugin's install, which names
skilletor's marketplace for the settings requirement. Unset outside a plugin.

=head2 host

  host => { name => 'box', os => 'linux' }

The render context's C<host>. Default: the machine's host name and its OS as
Node's C<process.platform> names it (C<linux>, C<darwin>, C<win32>, …).

=head2 user

  user => { name => 'me', home => $home }

The render context's C<user>. Default: the login name of the effective user,
as Node's C<os.userInfo()> finds it, and L<Skilletor::Resolver/home>. A user
without a passwd entry fails every item's build with Node's message, as the
reference's does.

=head2 sync

  my $report = $engine->sync( scope => 'user' | 'project' | 'all', force => 0 );

  {
    scopes => [ {
      scope => 'user',
      added => [ { key, type, name, source } ], updated => [...], removed => [...],
      unchanged => [...], skipped => [...],
      conflicts => [ { path, replace?, notFile? } ], overwritten => [ { path } ],
      warnings => [...], trustRequests => [ { name, kind, url } ],
      gitignoreUpdated? => [ '.claude/.gitignore', '.worktreeinclude' ],
      settingsSkipped?  => [...],
      settingsUpdated?  => { path, enabled => [...], declared => [...] },
      briefingMissing?  => [ { key, harness, missing => [...] } ],
    } ],
    warnings? => [...],     # the run's: Codex has not trusted the SessionStart hook
    notes?    => [...],     # what an active harness got no copy of (spec §16.3)
    error? => $message,
  }

C<force> adopts a file in an item's way, deletes one at a claimed path or
replaces a link (spec §6.3). L<Skilletor::Report/report_text> words the
report as the CLI does, L<Skilletor::Report/report_hook> as the hooks do. The
sync honours L<Skilletor::Resolver/fetch>: C<never> syncs from the cache
alone.

The options the reference's hooks set (spec §8):

=over 4

=item * C<< if_changed => 1 >>: once the sync lock is held, a L</check> with
C<local> decides – nothing changed (and no error): nothing runs and the report
is C<< { scopes => [] } >>. A run that waited out another's sync of the same
change finds nothing left.

=item * C<< deadline => $epoch_ms >>: a scope whose sources are resolved only
after it does not reach its apply; the sync dies with C<sync stopped before
applying the E<lt>scopeE<gt> scope: its sources took too long>, the scope's
records are dropped as after any sync that stopped, and any earlier scope that
completed remains in place.

=item * C<< lock_timeout_ms => $ms >>: how long this call waits for the sync
lock, over L<Skilletor::Resolver/lock_timeout_ms>.

=back

=head2 check

  my $check = $engine->check( scope => 'all', local => 0 );
  # { changed, sources => [ { name, scope, changed } ], warnings,
  #   targetsChanged?, layoutChanged?, declaredChanged?, varsChanged?, trustRequests?, error? }

Whether a sync is due, without one: source versions (C<git ls-remote>, an
HTTP C<HEAD>; a C<local> source always counts as changed), the drift of the
lock against the config and the layout, the render inputs. It reads no
installed file – an edited file is a sync's to overwrite, not drift. With
C<local> no source is asked (no fetch, no C<ls-remote>, no request; C<sources>
stays empty): the lock against the config, the layout and the render inputs
alone. Untrusted sources are named either way.

=head2 status

  my $status = $engine->status( scope => 'all' );
  # { scopes => [ { scope, targets, declared => [ { key, source, installed, via?, skipped?,
  #   partial?, briefingMissing? } ], orphans, wildcards, bundles, trustRequests,
  #   sourceVersions } ], projectIsHome?, warnings?, error? }

Offline and read-only: the lock and the config.

=head2 codex_rules_files

  my @files = $engine->codex_rules_files;

The Codex rules files the SessionStart hook injects (spec §14.8): the user
scope's, then the project's, each when it exists and Codex is a target of that
scope. When the config or the targets cannot be loaded, every existing file
(the last good state). Reads no source and never throws.

=head2 hermes_opt_in_hint

  my $line = $engine->hermes_opt_in_hint;
  # Hermes gets no skills: "hermes" is not in "targets"; to opt in, set
  # "targets": ["claude", "hermes"] in ~/.claude/skilletor.json

For a run Hermes started (spec §16.4): while C<hermes> is no machine target,
the line that says how to opt in, naming the targets in use plus C<hermes>.
Undef when Hermes is a target, or when the config or the targets cannot be read
(that error is reported on its own). Never throws.

=head2 RENDER_FORMAT

The render format hashed into the render inputs (the reference's, 2).

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
