package Skilletor::Engine;
# ABSTRACT: sync, check and status for Claude Code – the reference's engine pipeline after the resolve

use Moo;
use utf8;
use Carp qw( croak );
use Encode ();
use JSON::MaybeXS ();
use Scalar::Util qw( blessed refaddr );
use Skilletor::Apply qw( apply );
use Skilletor::Backend;
use Skilletor::Briefing qw( briefing_warning missing_skills skill_roots );
use Skilletor::Bundles qw( matches_pattern );
use Skilletor::ClaudeSettings qw( plan_claude_settings );
use Skilletor::Config;
use Skilletor::Entry qw( HARNESSES ITEM_TYPES );
use Skilletor::FSUtil qw( encode_text hash_bytes is_absolute path_join path_resolve same_path to_posix write_text );
use Skilletor::Gitignore qw(
  CODEX_ENTRIES LOCAL_ENTRIES PROJECT_CLAUDE_ENTRIES SKILL_GITIGNORE WORKTREE_INCLUDE
  block_entries has_block skill_gitignore_path update_gitignore update_worktree_include with_skill_gitignore
);
use Skilletor::GitEnv qw( git_env );
use Skilletor::JSON qw( js_ordered js_sort_keys js_stringify js_type );
use Skilletor::Lock qw( key_to_type_name parse_lock_key read_lock );
use Skilletor::Process qw( run_command );
use Skilletor::Render qw( build executables templates_of );
use Skilletor::Report qw( empty_scope_report );
use Skilletor::Source::Git;
use Skilletor::Source::Url;
use Skilletor::State;
use Skilletor::Targets qw(
  all_roots default_hermes_home detect_harnesses is_block_type is_local_type lacks_local_prefix lock_key
  place_output receivers root_of root_of_key select_targets supports target_gaps
);
use namespace::clean;

extends 'Skilletor::Resolver';

our $VERSION = '0.001';

# What a sync makes of unchanged sources and inputs (the reference's RENDER_FORMAT, k107): part
# of the render-inputs hash, so both implementations record and compare the same one.
use constant RENDER_FORMAT => 2;

use constant RULES_FILE => 'skilletor-rules.md';

my %TYPE_DIR = ( skill => 'skills', agent => 'agents', rule => 'rules' );

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

# `CLAUDE_PLUGIN_ROOT`: the running plugin's install, naming skilletor's marketplace (spec §6.8).
has plugin_root => (
  is      => 'lazy',
  builder => sub { $ENV{CLAUDE_PLUGIN_ROOT} },
);

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

sub _true  { JSON::MaybeXS::true() }
sub _false { JSON::MaybeXS::false() }

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

# Where a scope's roots live. Hermes is never a target here: its home is the recorded one.
sub _root_context {
  my ( $self, $scope ) = @_;
  my $recorded = eval { Skilletor::State->new( root => $self->state_root )->hermes_home };
  return {
    base        => $self->_base_of($scope),
    scope       => $scope,
    claude_dir  => $self->claude_dir,
    codex_home  => $self->_codex_home_of,
    hermes_home => $recorded // default_hermes_home( $self->home ),
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

# Config and targets as a sync needs them: no harness is a config error.
sub _load_strict {
  my ( $self ) = @_;
  my $config  = Skilletor::Config->load( home => $self->home, claude_config_dir => $self->claude_config_dir, project_dir => $self->project_dir_of );
  my $markers = $self->markers;
  my $targets = select_targets( { user => $config->user->{targets}, project => $config->project ? $config->project->{targets} : undef },
    detect_harnesses($markers), $markers );
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

# The Perl port installs for Claude Code alone: a scope that targets another harness is refused
# whole, before anything is read or written.
sub _unsupported_targets {
  my ( $self, $targets, @scopes ) = @_;
  for my $s (@scopes) {
    my @other = grep { $_ ne 'claude' } @{ $targets->{ $s->[0] } };
    next unless @other;
    my $where = $s->[0] eq 'user' ? '~/.claude/skilletor.json' : q{the project's .claude/skilletor.json or skilletor.local.json};
    return 'the '.$s->[0].' scope targets '.join( ', ', @other ).'; the Perl port of skilletor installs for Claude Code only '
      .'(set "targets": ["claude"] in '.$where.', or use the skilletor CLI)';
  }
  return undef;
}

# What a Claude-only sync would have to leave half done: lock entries of another harness (the
# reference removes them from their roots), sections of the Codex rules file, the rules file.
sub _foreign_state {
  my ( $self, @scopes ) = @_;
  for my $s (@scopes) {
    my $scope = $s->[0];
    my $rc    = $self->_root_context($scope);
    my $lock_path = $self->_lock_path($scope);
    my $lock  = eval { read_lock($lock_path) } or next;    # unreadable: the scope's sync reports it
    my @keys  = grep {
      my $k = parse_lock_key($_);
      $lock->{$_}{block} || ( defined $k->{harness} && $k->{harness} ne 'claude' && defined root_of_key( $rc, $_ ) );
    } keys %$lock;
    if (@keys) {
      return $lock_path.' holds items of another harness ('.join( ', ', js_sort_keys(@keys) ).'); the Perl port of skilletor '
        .'installs for Claude Code only and leaves them to the skilletor CLI (run skilletor sync)';
    }
    my $rules = path_join( root_of( $rc, 'codex', 'rule' ), RULES_FILE );
    if ( -e encode_text($rules) ) {
      return $rules.' exists; the Perl port of skilletor does not maintain the Codex rules file and leaves it to the '
        .'skilletor CLI (run skilletor sync)';
    }
  }
  return undef;
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
  my $state = Skilletor::State->new( root => $self->state_root );
  my $report = $state->with_lock(
    sub {
      Skilletor::Source::Url->sweep_cache( $self->cache_root );
      Skilletor::Source::Git->sweep_cache( $self->cache_root );
      my ( $config, $targets );
      return { scopes => [], error => _message($@) } unless eval { ( $config, $targets ) = $self->_load_strict; 1 };
      my @scopes = _scopes_of( $config, $sel );
      if ( defined( my $why = $self->_unsupported_targets( $targets, @scopes ) // $self->_foreign_state(@scopes) ) ) {
        return { scopes => [], error => $why };
      }
      my $run = {};
      my $out = { scopes => [] };
      for my $s (@scopes) {
        my ( $scope, $scope_cfg ) = @$s;
        my $rep = $self->_sync_scope( $config, $scope_cfg, $scope, $targets->{$scope}, \%opts, $state, $run );
        # The Hermes home record lives while Hermes is a target; it never is here.
        $state->put_hermes_home(undef) if $scope eq 'user';
        unshift @{ $rep->{warnings} }, @{ $targets->{warnings} } if $scope eq 'project';
        push @{ $out->{scopes} }, $rep;
      }
      return $out;
    },
    timeout_ms => $self->lock_timeout_ms,
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
  my ( $self, $config, $scope_cfg, $scope, $harnesses, $opts, $state, $run ) = @_;
  my $target_dir = $self->_target_dir($scope);
  my $base       = $self->_base_of($scope);
  my $rc         = $self->_root_context($scope);
  my $lock_path  = path_join( $target_dir, 'skilletor.lock.json' );
  my $old_lock   = read_lock($lock_path);
  my $gitignore_on = $scope_cfg->{gitignore} ? 1 : 0;
  my $inputs;
  my $inputs_of = sub { $inputs //= $self->_render_inputs_of( $scope, $scope_cfg ) };

  my @plan;
  # Entries this version cannot place (an unknown harness prefix) are never touched.
  my @keep = grep { !defined root_of_key( $rc, $_ ) } keys %$old_lock;
  my %key_info;
  my %held_back;    # sources with an item the Perl port does not build (templates)
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
      return 0 unless @targets;
      for my $h (@targets) {
        my $key = lock_key( $h, $item->{target} );
        $key_info{$key} = { key => $key, type => $item->{type}, name => $item->{name}, source => $item->{source} };
      }
      return 1;
    },
    build => sub {
      my ( $item, $extra, $found, $warnings ) = @_;
      my ( $r, $cat, $ci ) = @{$found}{qw( r cat item )};
      for my $h ( $receivers_of->( $item->{type} ) ) {
        my $key = lock_key( $h, $item->{target} );
        if ( my @tpl = templates_of($ci) ) {
          # The Perl port renders no Nunjucks: the item stays as it is installed, as for an
          # unreachable source, and its source counts as not reached for the records.
          push @$warnings, $item->{type}.' '.$item->{name}.'@'.$item->{source}.' is a Nunjucks template ('.join( ', ', @tpl )
            .') the Perl port of skilletor does not render; an installed copy stays';
          push @keep, $key if exists $old_lock->{$key};
          $held_back{ $item->{source} } = 1;
          next;
        }
        my ( $output, $executable );
        my $ok = eval {
          $output = build( $ci, $r->{dir} );
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
  my $out = empty_scope_report($scope);
  $out->{warnings}      = $rep->{warnings};
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
      elsif ( $in_use && $root eq $codex_root && $holds_managed->($root) ) {
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
  if ( my $settings = $self->_claude_settings_plan( $scope, $scope_cfg, $harnesses ) ) {
    my $file  = $self->_settings_file;
    my $label = _scope_label( $scope, $base, $file );
    push @$warnings, @{ $settings->{warnings} };
    $out->{settingsSkipped} = [ @{ $settings->{warnings} } ] if @{ $settings->{warnings} };
    if ( defined $settings->{next} ) {
      if ( eval { write_text( $file, $settings->{next} ); 1 } ) {
        $out->{settingsUpdated} = { path => $label, enabled => $settings->{enabled}, declared => $settings->{declared} };
      }
      else {
        push @$warnings, $label.' not updated: '._message($@);
      }
    }
  }

  # Managed paths git still tracks (spec §6.4): only what this run wrote or adopted.
  if ($gitignore_on) {
    my @written = map { { root => root_of_key( $rc, $_->{key} ) // $target_dir, key => $_->{key}, path => $_->{path} } } @{ $result->{written} };
    push @$warnings, $self->_tracked_warnings( $scope, $base, \@written );
  }

  my $to_change = sub {
    my ( $key ) = @_;
    return $key_info{$key} // { key => $key, %{ key_to_type_name($key) }, source => ( $info->{old_lock}{$key} || {} )->{source} // '?' };
  };
  $out->{$_} = [ map { $to_change->($_) } @{ $result->{$_} } ] for qw( added updated removed unchanged skipped );
  my $shown = sub {
    my ( $c ) = @_;
    my $root = root_of_key( $rc, $c->{key} ) // $target_dir;
    return $root eq $target_dir ? $c->{path} : $label_of->( path_join( $root, $c->{path} ) );
  };
  $out->{conflicts} = [
    map {
      my $c = { path => $shown->($_) };
      $c->{replace} = $_->{replace} if $_->{replace};
      $c->{notFile} = $_->{notFile} if $_->{notFile};
      $c;
    } @{ $result->{conflicts} }
  ];
  $out->{overwritten} = [ map { { path => $shown->($_) } } @{ $result->{overwritten} } ];
  for my $l ( @{ $result->{leftInPlace} } ) {
    push @$warnings, $shown->($l).' is a symbolic link: files of '.$l->{key}.' behind it left in place (never deleted through a link)';
  }

  # Briefing check (spec §6.7): every agent the lock holds now, from its installed file.
  my $final_lock = read_lock($lock_path);
  my @briefing = $self->_briefing_of( $scope, $final_lock );
  push @$warnings, briefing_warning( parse_lock_key( $_->{key} )->{name}, $_->{harness}, $_->{missing} ) for @briefing;
  $out->{briefingMissing} = \@briefing if @briefing;

  # The records `check` compares with (spec §14.3). A source counts as reached when it was
  # resolved and scanned – and, in the Perl port, when it had no item left unbuilt for being a
  # template: what the port left alone stays open for the next sync, the reference's included.
  my %resolved = %{ $info->{resolved} };
  my %catalogs = %{ $info->{catalogs} };
  my $reachable = sub {
    my ( $name ) = @_;
    return 0 unless $resolved{$name};
    return 0 if exists $catalogs{$name} && !defined $catalogs{$name};
    return $held_back{$name} ? 0 : 1;
  };
  my @drift = $self->_scope_drift( $scope, $scope_cfg, $harnesses, $final_lock, $info->{served} );
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
# not skilletor's to touch. Never throws.
sub _claude_settings_plan {
  my ( $self, $scope, $scope_cfg, $harnesses ) = @_;
  return undef unless $scope eq 'project';
  return undef if js_type( $scope_cfg->{claudeSettings} ) eq 'boolean' && !$scope_cfg->{claudeSettings};
  return undef unless grep { $_ eq 'claude' } @$harnesses;
  return undef unless -e encode_text( path_join( $self->_target_dir($scope), 'skilletor.json' ) );
  my $file  = $self->_settings_file;
  my $label = _scope_label( $scope, $self->project_dir_of, $file );
  my $plan  = eval {
    plan_claude_settings(
      file => $file, label => $label, project_dir => $self->project_dir_of,
      claude_dir => $self->claude_dir,
      plugin_root => ( defined $self->plugin_root && length $self->plugin_root ) ? $self->plugin_root : undef,
    );
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
    push @out, { key => $key, harness => $k->{harness}, missing => $missing } if $missing && @$missing;
  }
  return @out;
}

#### Drift (spec §14.3) ######################################################

my $SKILL_GITIGNORE_HASH = hash_bytes( encode_text(SKILL_GITIGNORE) );

# Every drift of a scope: targets, layout, declarations, each { kind, id, sources }.
sub _scope_drift {
  my ( $self, $scope, $scope_cfg, $harnesses, $lock, $served_by ) = @_;
  my @out;
  for my $g ( @{ target_gaps( [ keys %$lock ], $harnesses, $scope ) } ) {
    my $source = $lock->{ $g->{key} }{source};
    push @out, defined $g->{missing}
      ? { kind => 'targets', id => 'missing:'.$g->{missing}.'@'.( $source // 'undefined' ), sources => [$source] }
      : { kind => 'targets', id => 'orphan:'.$g->{key}, sources => [] };
  }
  my $settings = $self->_claude_settings_plan( $scope, $scope_cfg, $harnesses );
  push @out, { kind => 'layout', id => 'layout:claude-settings', sources => [] } if $settings && defined $settings->{next};
  return ( @out, $self->_layout_drift( $scope, $scope_cfg, $lock ), _declared_drift( $scope_cfg, $scope, $harnesses, $lock, $served_by ) );
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
  unless ( eval { ( $config, $targets ) = $self->_load_strict; 1 } ) {
    return { changed => _false, sources => [], warnings => [], error => _message($@) };
  }
  my @scopes = _scopes_of( $config, $sel );
  if ( defined( my $why = $self->_unsupported_targets( $targets, @scopes ) ) ) {
    return { changed => _false, sources => [], warnings => [], error => $why };
  }
  my $state = Skilletor::State->new( root => $self->state_root );
  my $out = { changed => _false, sources => [], warnings => [] };
  my %field = ( targets => 'targetsChanged', layout => 'layoutChanged', declared => 'declaredChanged' );

  for my $s (@scopes) {
    my ( $scope, $scope_cfg ) = @$s;
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
    } $self->_scope_drift( $scope, $scope_cfg, $targets->{$scope}, $old_lock );
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
          push @{ $out->{trustRequests} }, { scope => $scope, %{ Skilletor::Backend->trust_request( $name, $backend ) } };
          return 1;
        }
        my $version = _checked_version( $read->{$name}, $backend, $old_lock, $name );
        my $changed = Skilletor::Backend->make( $backend, $self->cache_root, $self->timeout_ms )->check($version) ? 1 : 0;
        push @{ $out->{sources} }, { name => $name, scope => $scope, changed => $changed ? _true : _false };
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
  return { scopes => [], error => _message($@) } unless eval { ( $config, $targets ) = $self->_load_strict; 1 };
  my @scopes = _scopes_of( $config, $sel );
  if ( defined( my $why = $self->_unsupported_targets( $targets, @scopes ) ) ) {
    return { scopes => [], error => $why };
  }
  my $state = Skilletor::State->new( root => $self->state_root );
  my $out = { scopes => [] };
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
      my $d = { key => $_->{key}, source => $_->{source}, installed => ( $entry && !$entry->{skipped} ) ? _true : _false };
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
        push @declared, { key => $key, source => $entry->{source}, installed => _false, via => $label, skipped => $entry->{skipped} };
        next;
      }
      my $d = { key => $key, source => $entry->{source}, installed => _true, via => $label };
      $d->{partial} = _true if $entry->{partial};
      push @declared, $d;
      $via{ refaddr $_ }{ $k->{target} } = 1 for @covering;
    }
    my %installed = map { ( $_->{key} => 1 ) } grep { $_->{installed} } @declared;
    my %missing = map { ( $_->{key} => $_->{missing} ) } $self->_briefing_of( $scope, $lock, \%installed );
    $_->{briefingMissing} = $missing{ $_->{key} } for grep { $missing{ $_->{key} } } @declared;
    push @{ $out->{scopes} }, {
      scope     => $scope,
      targets   => [@$active],
      declared  => \@declared,
      orphans   => \@orphans,
      wildcards => [ map { { type => $_->{type}, source => $_->{source}, entry => $_->{raw}, installed => 0 + keys %{ $via{ refaddr $_ } // {} } } }
          @{ $scope_cfg->{wildcards} } ],
      bundles => [ map { { name => $_->{name}, source => $_->{source}, entry => $_->{raw}, installed => 0 + keys %{ $via{ refaddr $_ } // {} } } }
          @{ $scope_cfg->{bundles} } ],
      trustRequests  => \@trust,
      sourceVersions => $versions,
    };
  }
  return $out;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Skilletor::Engine - sync, check and status for Claude Code – the reference's engine pipeline after the resolve

=head1 VERSION

version 0.001

=head1 SYNOPSIS

  use Skilletor::Engine;

  my $engine = Skilletor::Engine->new( home => $ENV{HOME}, project_dir => $project );

  my $report = $engine->sync( scope => 'all', force => 0 );   # what `skilletor sync --json` prints
  my $check  = $engine->check( scope => 'all' );              # `skilletor check --json`
  my $status = $engine->status( scope => 'all' );             # `skilletor status --json`

=head1 DESCRIPTION

The reference's engine (C<engine.ts>) after the resolve: C<sync>, C<check>
and C<status> for Claude Code. It extends L<Skilletor::Resolver> – a sync runs
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
L<JSON::MaybeXS> booleans. The state records (C<render-inputs.json> with the
same C<RENDER_FORMAT>, C<sources-read.json>, C<unreached.json>) are the same
bytes too, so a C<check> of either implementation accepts what the other
synced: the shared conformance cases and F<t/52-parity-sync.t> hold both to
that. Like the reference, a sync holds the sync lock (L<Skilletor::State/with_lock>);
C<check> and C<status> read without it.

=head2 Claude Code only

The port installs for Claude Code alone. A scope whose targets name another
harness – C<"targets"> with C<codex> or C<hermes>, or Codex detected on the
machine without C<"targets"> – is refused whole: C<sync>, C<check> and
C<status> return the report with an C<error> and touch nothing. A project
narrowed to no harness in use is no error (the reference's warning). A C<sync>
is also refused, before anything is written, when a scope holds state of
another harness the reference would change: lock entries of Codex or Hermes
(the reference removes them from their roots), C<block> entries (sections of
the Codex rules file) or a Codex rules file (C<skilletor-rules.md>). Lock
entries of a harness neither knows are kept untouched, as the reference keeps
them. Run the skilletor CLI once on such a machine.

=head2 Templates

The port renders no Nunjucks. A declared item with a C<.njk> file is never
installed unrendered: the sync warns
(C<< skill greet@shared is a Nunjucks template (skills/greet/SKILL.md.njk) the
Perl port of skilletor does not render; an installed copy stays >>) and leaves
the item exactly as it is installed – files and lock entry, never deleted –
as for an item whose source cannot be reached. For the records the item's
source then counts as not reached: drift it keeps is not recorded as
unreached, its C<sources-read.json> entry stays what an earlier sync read, and
the scope's render inputs are not recorded. So C<check> – the port's and the
reference's – keeps asking for a sync, and the reference's next sync renders
the item. A C<renders-empty> skip can only come from a render; such lock
entries the reference left are kept like any other.

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

=head2 plugin_root

C<CLAUDE_PLUGIN_ROOT> by default: the running plugin's install, which names
skilletor's marketplace for the settings requirement. Unset outside a plugin.

=head2 sync

  my $report = $engine->sync( scope => 'user' | 'project' | 'all', force => 0 );

  {
    scopes => [ {
      scope => 'user',
      added => [ { key, type, name, source } ], updated => [...], removed => [...],
      unchanged => [...], skipped => [...],
      conflicts => [ { path, replace?, notFile? } ], overwritten => [ { path } ],
      warnings => [...], trustRequests => [ { name, kind, url } ],
      briefingMissing?  => [ { key, harness, missing => [...] } ],
      gitignoreUpdated? => [ '.claude/.gitignore', '.worktreeinclude' ],
      settingsUpdated?  => { path, enabled => [...], declared => [...] },
      settingsSkipped?  => [...],
    } ],
    error? => $message,
  }

C<force> adopts a file in an item's way, deletes one at a claimed path or
replaces a link (spec §6.3). L<Skilletor::Report/report_text> words the
report as the CLI does. The sync honours L<Skilletor::Resolver/fetch>:
C<never> syncs from the cache alone.

=head2 check

  my $check = $engine->check( scope => 'all' );
  # { changed, sources => [ { name, scope, changed } ], warnings,
  #   targetsChanged?, layoutChanged?, declaredChanged?, varsChanged?, trustRequests?, error? }

Whether a sync is due, without one: source versions (C<git ls-remote>, an
HTTP C<HEAD>; a C<local> source always counts as changed), the drift of the
lock against the config and the layout, the render inputs. It reads no
installed file – an edited file is a sync's to overwrite, not drift.

=head2 status

  my $status = $engine->status( scope => 'all' );
  # { scopes => [ { scope, targets, declared => [ { key, source, installed, via?, skipped?,
  #   partial?, briefingMissing? } ], orphans, wildcards, bundles, trustRequests,
  #   sourceVersions } ], projectIsHome?, error? }

Offline and read-only: the lock and the config.

=head2 RENDER_FORMAT

The render format hashed into the render inputs (the reference's, 2).

=head1 SUPPORT

=head1 CONTRIBUTING

Contributions are welcome! Please fork the repository and submit a pull request.

=head1 AUTHOR

Torsten Raudssus <getty@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by Torsten Raudssus <torsten@raudssus.de> L<https://raudssus.de/>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
