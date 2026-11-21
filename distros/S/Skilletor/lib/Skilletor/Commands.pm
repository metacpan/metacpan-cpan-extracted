package Skilletor::Commands;
# ABSTRACT: The CLI's config commands – add, trust, source list, source remove, available, install, uninstall – after the reference's commands.ts

use strict;
use warnings;

use Exporter qw( import );
use File::Basename qw( dirname );
use JSON::MaybeXS ();
use Scalar::Util qw( blessed );
use Skilletor::Backend;
use Skilletor::Bundles qw( expand_bundle matches_pattern same_identity );
use Skilletor::Catalog;
use Skilletor::Config;
use Skilletor::Entry qw( SOURCE_NAME_RULE WILDCARD is_source_name name_key );
use Skilletor::Error::Command;
use Skilletor::FSUtil qw( inner_segments path_join );
use Skilletor::JSON qw( js_ordered js_sort_keys js_stringify js_type );
use Skilletor::JSString qw( js_trim );
use Skilletor::Lock qw( parse_lock_key read_lock );
use Skilletor::Probe qw( make_probe );
use Skilletor::Resolver;
use Skilletor::Source::Git;
use Skilletor::Source::Url;
use Skilletor::Spec qw( resolve_spec );
use Skilletor::State;

our $VERSION = '0.008000';

our @EXPORT_OK = qw( add available config_path install source_list source_remove trust uninstall );

my @ADDRESS_KEYS = qw( git url local );
my %ADDRESS_KEY  = map { ( $_ => 1 ) } @ADDRESS_KEYS;
my %DEF_KEY      = map { ( $_ => 1 ) } qw( git ref url local path );
my %TYPE_DIR     = ( skill => 'skills', agent => 'agents', rule => 'rules' );

sub _fail { Skilletor::Error::Command->throw( $_[0] ) }

# The project root of a --project edit; the home dir as project dir has no project scope.
sub _project_root {
  my ( $engine ) = @_;
  my $dir = $engine->project_dir_of;
  return $dir if defined $dir;
  my $given = $engine->project_dir;
  _fail(
    ( defined $given && length $given )
    ? 'no project scope: the project directory is the home directory ('.$engine->home.'); '
      .'run from a project, pass --project-dir, or drop --project to edit the user config'
    : 'no project scope: no project directory'
  );
}

sub config_path {
  my ( $engine, $project ) = @_;
  return path_join( $project ? path_join( _project_root($engine), '.claude' ) : $engine->claude_dir, 'skilletor.json' );
}

# The config as the engine sees it: no project config when the project dir is the home dir.
sub _load {
  my ( $engine, %more ) = @_;
  return Skilletor::Config->load(
    home              => $engine->home,
    claude_config_dir => $engine->claude_config_dir,
    project_dir       => $engine->project_dir_of,
    %more,
  );
}

#### add #######################################################################

# Add a source to one config, trust it, sync. Never replaces a source (k101): a name the config
# already has keeps its entry untouched when it has the same backend and address – still trusted
# and synced, `kept` set – and is refused, before anything is written or trusted, when it has
# another one. A name load would refuse (k95) is refused first, a definition it would refuse
# (k110) next, a kept entry it would refuse (k116) before it is trusted; a spec's ref (k119) and
# path (k126) keep an entry only at that ref and path.
sub add {
  my ( $engine, %args ) = @_;
  my ( $name, $spec ) = @args{qw( name spec )};
  my $flag = $args{project} ? ' --project' : '';
  if ( defined $name && !is_source_name($name) ) {
    _fail( 'source name '.js_stringify($name).' is not valid ('.SOURCE_NAME_RULE.'); nothing was changed' );
  }
  my $path     = config_path( $engine, $args{project} );
  my $resolved = resolve_spec( $spec, $args{probe} // make_probe() );
  $name //= $resolved->{derivedName};
  my $def = js_ordered( $resolved->{kind} => $resolved->{value} );
  $def->{$_} = $resolved->{$_} for grep { exists $resolved->{$_} } qw( ref path );
  my $invalid = _load_refusal( $name, $def );
  _fail( 'cannot add '.$spec.': '.$invalid.'; nothing was changed' ) if defined $invalid;

  my $kept = Skilletor::Config->has_source_entry( $path, $name );
  if ($kept) {
    my $existing = Skilletor::Config->source_entry( $path, $name );
    my $ways = 'add it under another name (skilletor add <name> '.$spec.$flag.') '
      .'or remove the source first (skilletor source remove '.$name.$flag.').';
    unless ( _same_address( $engine, $name, $existing, $resolved ) ) {
      _fail( 'source "'.$name.'" in '.$path.' is '._address_text($existing).', not '.$resolved->{kind}.' '.$resolved->{value}
          .'; nothing was changed. '.ucfirst($ways) );
    }
    # A spec's ref (k119) is what the user asked for: keeping the entry at another would drop it.
    my $has = $existing->{ref};
    if ( exists $resolved->{ref} && !( js_type($has) eq 'string' && $has eq $resolved->{ref} ) ) {
      _fail( 'source "'.$name.'" in '.$path.' is '._address_text($existing).' '
          .( defined $has ? 'with ref '.js_stringify($has) : 'with no ref' ).', not ref '.js_stringify( $resolved->{ref} )
          .'; nothing was changed. Set its "ref" by hand, '.$ways );
    }
    # So is a spec's path (k126): the entry would go on offering what lies elsewhere in the repo.
    if ( exists $resolved->{path} && !_same_paths( $existing->{path}, $resolved->{path} ) ) {
      _fail( 'source "'.$name.'" in '.$path.' is '._address_text($existing).' '
          .( exists $existing->{path} ? 'with path '.js_stringify( $existing->{path} ) : 'with no path' )
          .', not path '.js_stringify( $resolved->{path} ).'; nothing was changed. Set its "path" by hand, '.$ways );
    }
    # Kept as written, so checked as load reads it: an entry the sync would refuse is not trusted.
    my $refused = _load_refusal( $name, $existing, $path );
    if ( defined $refused ) {
      _fail( 'cannot add '.$spec.': '.$refused.'; nothing was changed. Source "'.$name.'" there already has this address: '
          .'fix its entry by hand, or remove it (skilletor source remove '.$name.$flag.').' );
    }
    $def = _entry_def($existing);
  }
  else {
    Skilletor::Config->add_source( $path, $name, $def );
  }
  # add is the trust act.
  _trust_def( $engine, $name, $def );

  return { name => $name, def => $def, kept => $kept, report => $engine->sync };
}

# Why config load would refuse source $name defined as $def, by load's own check (k110) – with
# $file, as load words it for that file; undef when it would load.
sub _load_refusal {
  my ( $name, $def, $file ) = @_;
  return undef if eval { Skilletor::Config->source_fields( $def, ( defined $file ? $file.': ' : '' ).'sources.'.$name ); 1 };
  my $err = $@;
  die $err unless blessed $err && $err->isa('Skilletor::Error::Config');
  return $err->message;
}

# Does a config entry name the backend and address a spec resolved to? git and url compare as
# source identities (spec §15.6), a local path as the directory it names.
sub _same_address {
  my ( $engine, $name, $entry, $resolved ) = @_;
  return 0 unless js_type($entry) eq 'object';
  my $field = $entry->{ $resolved->{kind} };
  return 0 unless js_type($field) eq 'string';
  return same_identity( $field, $resolved->{value} ) if $resolved->{kind} ne 'local';
  my $dir = sub { Skilletor::Backend->resolve( { name => $name, local => $_[0], origins => {} }, $engine->home )->{address} };
  return $dir->($field) eq $dir->( $resolved->{value} ) ? 1 : 0;
}

# An entry's backends as written (`git https://…, local ~/dev/x`), else the entry as JSON.
sub _address_text {
  my ( $entry ) = @_;
  my @parts = js_type($entry) eq 'object'
    ? map { $_.' '.$entry->{$_} } grep { $ADDRESS_KEY{$_} && js_type( $entry->{$_} ) eq 'string' } keys %$entry
    : ();
  return @parts ? join( ', ', @parts ) : js_stringify($entry);
}

# Does an entry's `path`, as written, name the one directory $path? A string or a list of one,
# compared by segments (`./skills/` is `skills`); anything else does not.
sub _same_paths {
  my ( $entry, $path ) = @_;
  my $type = js_type($entry);
  $entry = $entry->[0] if $type eq 'array' && @$entry == 1;
  return 0 unless js_type($entry) eq 'string';
  my $segments = sub { my $s = inner_segments( $_[0] ); ref $s ? join( '/', @$s ) : undef };
  my $mine = $segments->($entry);
  my $theirs = $segments->($path);
  return defined $mine && defined $theirs && $mine eq $theirs ? 1 : 0;
}

# The source fields of an entry as written, in its key order (`path` a string or a list).
sub _entry_def {
  my ( $entry ) = @_;
  return js_ordered(
    map { ( $_ => $entry->{$_} ) } grep { $DEF_KEY{$_} && ( $_ eq 'path' || js_type( $entry->{$_} ) eq 'string' ) } keys %$entry
  );
}

#### source list ###############################################################

sub source_list {
  my ( $engine ) = @_;
  my $config = _load($engine);
  return [
    map {
      js_ordered( name => $_->{name}, def => _pick_def($_), origin => Skilletor::Backend->resolve( $_, $engine->home )->{origin} )
    } @{ $config->sources }
  ];
}

# A source's fields as merged, in the order the reference writes them.
sub _pick_def {
  my ( $s ) = @_;
  my $def = js_ordered();
  for my $key (qw( git ref url local )) {
    $def->{$key} = $s->{$key} if defined $s->{$key} && length $s->{$key};
  }
  $def->{path} = $s->{path} if exists $s->{path};
  return $def;
}

#### source remove #############################################################

sub source_remove {
  my ( $engine, %args ) = @_;
  my $name    = $args{name};
  my $project = $args{project} ? 1 : 0;
  my $path    = config_path( $engine, $project );
  unless ( Skilletor::Config->has_source_entry( $path, $name ) ) {
    _fail( 'source "'.$name.'" is not declared in the '.( $project ? 'project' : 'user' ).' config ('.$path.')'
        ._source_elsewhere( $engine, $name, $project ) );
  }
  my $stranded = _stranded_overrides( $engine, $name, $project );
  _fail($stranded) if defined $stranded;
  my $config = _removal_config( $engine, $path, $name );
  if ( _used_sources($config)->{$name} && !$args{force} ) {
    _fail( 'source "'.$name.'" still has installed items; use --force to remove anyway' );
  }
  Skilletor::Config->remove_source( $path, $name );
  return $engine->sync;
}

# The config a removal checks the source's use in: the engine's; or, when load refuses it, the
# config loaded with the entry being removed unchecked (k120). Any error left stops the command.
sub _removal_config {
  my ( $engine, $path, $name ) = @_;
  my $config;
  return $config if eval { $config = _load($engine); 1 };
  my $err = $@;
  die $err unless blessed $err && $err->isa('Skilletor::Error::Config');
  return _load( $engine, unchecked => { path => $path, name => $name } );
}

# Does an entry as written name a backend (k128)?
sub _gives_backend {
  my ( $entry ) = @_;
  return 0 unless js_type($entry) eq 'object';
  return ( grep { exists $entry->{$_} } @ADDRESS_KEYS ) ? 1 : 0;
}

# Why removing the source from the target config would leave other files' entries for it
# without a backend (k137); undef when it strands nothing.
sub _stranded_overrides {
  my ( $engine, $name, $project ) = @_;
  my $path = config_path( $engine, $project );
  return undef unless _gives_backend( Skilletor::Config->source_entry( $path, $name ) );
  my $root = $engine->project_dir_of;
  return undef unless defined $root;    # the user config alone: no other file
  my $local = path_join( $root, '.claude', 'skilletor.local.json' );
  my $other = config_path( $engine, !$project );
  my @others = grep { Skilletor::Config->has_source_entry( $_->{path}, $name ) } (
    { path => $other, shown => 'the '.( $project ? 'user' : 'project' ).' config ('.$other.')',
      way => 'skilletor source remove '.$name.( $project ? '' : ' --project' ) },
    { path => $local, shown => $local, way => 'edit '.$local.' by hand' },
  );
  return undef if !@others || grep { _gives_backend( Skilletor::Config->source_entry( $_->{path}, $name ) ) } @others;
  my $many = @others > 1;
  return 'source "'.$name.'" in the '.( $project ? 'project' : 'user' ).' config ('.$path.') gives its only "git", "url" or "local", '
    .'and the '.( $many ? 'entries' : 'entry' ).' in '.join( ' and ', map { $_->{shown} } @others ).' '.( $many ? 'have' : 'has' ).' none: '
    .'config load would refuse '.( $many ? 'those entries' : 'that entry' ).' once this one is gone. '
    .'Remove '.( $many ? 'those entries' : 'that entry' ).' first ('.join( '; ', map { $_->{way} } @others ).'), '
    .'or give '.( $many ? 'one of them' : 'it' ).' a "git", "url" or "local" of its own; nothing was changed.';
}

# Where else a source is declared: the other scope's config, the project's local file.
sub _source_elsewhere {
  my ( $engine, $name, $project ) = @_;
  my $root = $engine->project_dir_of;
  return '; it is not a configured source' unless defined $root;
  my $local = path_join( $root, '.claude', 'skilletor.local.json' );
  my @hits;
  if ( Skilletor::Config->has_source_entry( config_path( $engine, !$project ), $name ) ) {
    push @hits, $project ? 'the user config declares it (run without --project)' : 'the project config declares it (use --project)';
  }
  push @hits, $local.' declares it (edit that file by hand)' if Skilletor::Config->has_source_entry( $local, $name );
  return '; '.( @hits ? join( '; ', @hits ) : 'it is not a configured source' );
}

# Sources an explicit entry, a wildcard or a bundle of any scope names.
sub _used_sources {
  my ( $config ) = @_;
  my %used;
  for my $scope ( grep { defined } $config->user, $config->project ) {
    $used{ $_->{source} } = 1 for @{ $scope->{install} }, @{ $scope->{wildcards} }, @{ $scope->{bundles} };
  }
  return \%used;
}

#### available #################################################################

sub available {
  my ( $engine, %args ) = @_;
  my $config    = _load($engine);
  my $installed = _installed_set( $engine, $config );
  my %declared  = map { ( Skilletor::Resolver->bundle_label($_) => 1 ) }
    @{ $config->user->{bundles} }, @{ $config->project ? $config->project->{bundles} : [] };
  my @names = defined $args{source} && length $args{source} ? ( $args{source} ) : $config->source_names;
  # A resolve writes the source cache, a scan reads it: under the sync lock (spec §6.5).
  my $list = _with_sync_lock( $engine, sub { _list_available( $engine, $config, $_[0], \@names, $installed, \%declared ) } );
  return $list;
}

sub _list_available {
  my ( $engine, $config, $state, $names, $installed, $declared ) = @_;
  my @out;
  for my $name (@$names) {
    # What install would read: the user config's definition for a user source (the user scope's,
    # spec §3), the merged one for a source only a project declares.
    my $src = $config->user_source($name) // $config->source($name) // _fail( 'unknown source: '.$name );
    my $backend = Skilletor::Backend->resolve( $src, $engine->home );
    next unless $state->is_trusted( $name, $backend );    # only trusted
    my $loc = Skilletor::Backend->make( $backend, $engine->cache_root )->resolve;
    my $cat = Skilletor::Catalog->scan( $loc->{dir}, $backend->{path} );
    for my $item ( @{ $cat->{items} } ) {
      my $entry = js_ordered( type => $item->{type}, name => $item->{name} );
      $entry->{description} = $item->{description} if defined $item->{description};
      $entry->{source}      = $name;
      $entry->{installed}   = _bool( $installed->{ _installed_key( $TYPE_DIR{ $item->{type} }.'/'.$item->{name}, $name ) } );
      $entry->{error}       = $item->{error} if defined $item->{error};
      push @out, $entry;
    }
    for my $b ( @{ $cat->{bundles} } ) {
      my $entry = js_ordered( type => 'bundle', name => $b->{name} );
      $entry->{description} = $b->{def}{description} if $b->{def};
      $entry->{source}      = $name;
      $entry->{installed}   = _bool( $declared->{ Skilletor::Resolver->bundle_label( { name => $b->{name}, source => $name } ) } );
      my $e;
      if ( eval { $e = expand_bundle( $cat, $b->{name} ); 1 } ) {
        # Members of other sources as written, with their address (spec §15.6).
        $entry->{members} = [ js_sort_keys( ( map { $_->{type}.':'.$_->{name} } @{ $e->{items} } ), map { $_->{type}.':'.$_->{entry} } @{ $e->{foreign} } ) ];
        $entry->{vars} = $b->{def}{vars};
      }
      else {
        my $err = $@;
        die $err unless blessed $err && $err->isa('Skilletor::Error::Bundle');
        $entry->{error} = $err->message;
      }
      push @out, $entry;
    }
  }
  return \@out;
}

sub _bool { $_[0] ? JSON::MaybeXS::true() : JSON::MaybeXS::false() }

# Run $code holding the sync lock, the caches swept first, as a sync runs (the reference's
# withSyncLock); $code gets the state.
sub _with_sync_lock {
  my ( $engine, $code ) = @_;
  my $state = Skilletor::State->new( root => $engine->state_root, read_once => 1 );
  my $result = $state->with_lock(
    sub {
      Skilletor::Source::Url->sweep_cache( $engine->cache_root );
      Skilletor::Source::Git->sweep_cache( $engine->cache_root );
      return $code->($state);
    },
    timeout_ms => $engine->lock_timeout_ms,
  );
  return $result;
}

# An available item's identity: its name ignores case, its target directory and source alias do not.
sub _installed_key {
  my ( $target, $source ) = @_;
  my $slash = index $target, '/';
  return substr( $target, 0, $slash + 1 ).name_key( substr( $target, $slash + 1 ) ).'@'.$source;
}

# `<typedir>/<name>@<source>` of every item an explicit entry of either scope declares or a lock
# of either scope holds – under any target, unless it rendered empty there.
sub _installed_set {
  my ( $engine, $config ) = @_;
  my %set;
  $set{ _installed_key( $_->{target}, $_->{source} ) } = 1 for @{ $config->user->{install} }, @{ $config->project ? $config->project->{install} : [] };
  my $project = $engine->project_dir_of;
  for my $dir ( $engine->claude_dir, defined $project ? path_join( $project, '.claude' ) : () ) {
    my $lock = read_lock( path_join( $dir, 'skilletor.lock.json' ) );
    for my $key ( keys %$lock ) {
      my $entry = $lock->{$key};
      next if $entry->{skipped};    # renders empty here: nothing installed
      $set{ _installed_key( parse_lock_key($key)->{target}, $entry->{source} // 'undefined' ) } = 1;
    }
  }
  return \%set;
}

#### install ###################################################################

# Plan every edit first, so a failure – or a missing source without a TTY – edits nothing: each
# item checked against the sources the target scope's sync resolves against (spec §3), its
# source resolved and scanned under the sync lock (spec §6.5), released before any question and
# before the sync, which takes it itself. Then the sources the bundles miss, then the edits in
# the order planned, the sources added last, then the sync.
sub install {
  my ( $engine, %args ) = @_;
  my $project = $args{project} ? 1 : 0;
  my $path    = config_path( $engine, $project );
  my $config  = _load($engine);
  my $state   = Skilletor::State->new( root => $engine->state_root );
  my $scope   = $project ? 'project' : 'user';
  my %catalogs;
  my $catalog_of = sub {
    my ( $source, $backend ) = @_;
    return $catalogs{$source} //=
      Skilletor::Catalog->scan( Skilletor::Backend->make( $backend, $engine->cache_root )->resolve->{dir}, $backend->{path} );
  };

  my ( @edits, @bundles );
  my $plan_item = sub {
    my ( $spec ) = @_;
    my $p = _parse_item_spec($spec);
    my ( $explicit_type, $name, $source ) = @{$p}{qw( type name source )};
    my $src = $config->source_of( $scope, $source );
    unless ($src) {
      my $hint = !$project && $config->source($source) ? ' in the user config (a project declares it: use --project)' : '';
      _fail( 'unknown source: '.$source.$hint );
    }
    my $backend = Skilletor::Backend->resolve( $src, $engine->home );
    _fail( 'source "'.$source.'" is not trusted; run: skilletor trust '.$source ) unless $state->is_trusted( $source, $backend );
    if ( index( $name, WILDCARD ) >= 0 ) {
      # Expanded at sync time; an empty match is fine here (items may arrive later).
      push @edits, sub { Skilletor::Config->add_install_entry( $path, $explicit_type, $name.'@'.$source ) };
      return;
    }
    my $cat = $catalog_of->( $source, $backend );
    my $has_bundle = grep { $_->{name} eq $name } @{ $cat->{bundles} };
    my @matches = $p->{bundle} ? () : grep { $_->{name} eq $name && ( !$explicit_type || $_->{type} eq $explicit_type ) } @{ $cat->{items} };
    # Without a prefix, a name only a bundle has is that bundle (spec §15.5).
    if ( $p->{bundle} || ( !$explicit_type && $has_bundle && !@matches ) ) {
      push @bundles, { name => $name, foreign => _check_bundle( $cat, $name, $source ) };
      push @edits, sub { Skilletor::Config->add_bundle_entry( $path, $name.'@'.$source ) };
      return;
    }
    unless (@matches) {
      my $suggestions = join ', ', _first8( map { $_->{type}.':'.$_->{name} } @{ $cat->{items} } );
      _fail( 'unknown item "'.$name.'" in '.$source.( length $suggestions ? ' (available: '.$suggestions.')' : '' ) );
    }
    if ( @matches > 1 || ( !$explicit_type && $has_bundle ) ) {
      my @options = map { $_->{type}.':'.$name.'@'.$source } @matches;
      push @options, 'bundle:'.$name.'@'.$source if !$explicit_type && $has_bundle;
      _fail( '"'.$name.'" is ambiguous in '.$source.'; use one of: '.join( ', ', @options ) );
    }
    my $type = $matches[0]{type};
    # An error of the item itself (spec §4.1) fails before any edit, as a broken bundle's does.
    _fail( $source.': '.$type.' '.$name.': '.$matches[0]{error} ) if defined $matches[0]{error};
    push @edits, sub { Skilletor::Config->add_install_entry( $path, $type, $name.'@'.$source ) };
  };
  _with_sync_lock( $engine, sub { $plan_item->($_) for @{ $args{items} }; return } );

  for my $addition ( @{ _missing_sources( $engine, $config, \@bundles, $path, $project, $args{prompt} ) } ) {
    push @edits, sub {
      Skilletor::Config->add_source( $path, $addition->{name}, $addition->{def} );
      _trust_def( $engine, $addition->{name}, $addition->{def} );    # as `add`: adding is the act of trust (spec §4.3)
    };
  }
  $_->() for @edits;
  return $engine->sync;
}

# The first eight of a list, as the reference's slice(0, 8).
sub _first8 { @_ > 8 ? @_[ 0 .. 7 ] : @_ }

# Sources the bundles name by address that no configured source the target scope sees serves
# (spec §15.6), once per identity. With a prompter each is offered for adding; without one the
# command fails, naming the `skilletor add` commands. None is one config load would refuse
# (k110): such an address is already an error of its bundle (k115, spec §15.4). Returns the
# sources to add: [ { name, def, url } ].
sub _missing_sources {
  my ( $engine, $config, $bundles, $path, $project, $prompt ) = @_;
  my $scope = $project ? 'project' : 'user';
  my @missing;
  for my $b (@$bundles) {
    for my $f ( @{ $b->{foreign} } ) {
      next if defined Skilletor::Resolver::_serving_source( $config, $scope, $f->{url} );
      push @missing, { bundle => $b->{name}, f => $f } unless grep { same_identity( $_->{f}{url}, $f->{url} ) } @missing;
    }
  }
  return [] unless @missing;
  my %taken = map { ( $_->{name} => $_->{git} // $_->{url} // $_->{local} // '' ) } @{ $config->sources };
  # A name is free unless $path, the config the source goes into, has it – whatever its address:
  # the prompt never writes over an entry, as `add` never replaces one (k102) – or a source with
  # another address holds it.
  my $free = sub {
    my ( $name, $url ) = @_;
    return !Skilletor::Config->has_source_entry( $path, $name ) && ( !exists $taken{$name} || same_identity( $taken{$name}, $url ) );
  };
  my $suggest = sub {
    my ( $f ) = @_;
    return $f->{derivedName} if $free->( $f->{derivedName}, $f->{url} );
    my $n = 2;
    $n++ until $free->( $f->{derivedName}.'-'.$n, $f->{url} );
    return $f->{derivedName}.'-'.$n;
  };
  my $flag = $project ? ' --project' : '';
  unless ($prompt) {
    my @lines = map { '  skilletor add '.$suggest->( $_->{f} ).' '.$_->{f}{spec}.$flag } @missing;
    my %seen;
    my $names = join ', ', grep { !$seen{$_}++ } map { $_->{bundle} } @missing;
    _fail( 'bundle '.$names." needs sources you don't have yet; nothing was changed. Add them, then install again:\n"
        .join( "\n", @lines ) );
  }
  my @out;
  for my $m (@missing) {
    my ( $bundle, $f ) = @{$m}{qw( bundle f )};
    my $fallback = $suggest->($f);
    my $question = 'bundle '.$bundle." needs a source you don't have yet: ".$f->{spec}." \x{2192} ".$f->{url}." \x{2014} "
      .'add it as ['.$fallback.']? (name, or n to skip)';
    my $note = '';
    for ( ;; ) {
      my $answer = js_trim( $prompt->( $note.$question ) );
      last if $answer =~ /\A(?:n|no)\z/i;
      my $name = length $answer ? $answer : $fallback;
      unless ( is_source_name($name) ) {
        $note = '"'.$name.'" is not a valid source name. ';
        next;
      }
      unless ( $free->( $name, $f->{url} ) ) {
        my $own = Skilletor::Config->has_source_entry( $path, $name ) ? _address_text( Skilletor::Config->source_entry( $path, $name ) ) : $taken{$name};
        $note = '"'.$name.'" is already a source with another address ('.$own.'). ';
        next;
      }
      push @out, { name => $name, def => js_ordered( $f->{kind} eq 'git' ? 'git' : 'url', $f->{url} ), url => $f->{url} };
      $taken{$name} = $f->{url};
      last;
    }
  }
  return \@out;
}

# A bundle must exist and expand before it is declared (errors of spec §15.4); returns its
# entries of other sources.
sub _check_bundle {
  my ( $cat, $name, $source ) = @_;
  unless ( grep { $_->{name} eq $name } @{ $cat->{bundles} } ) {
    my $known = join ', ', _first8( map { $_->{name} } @{ $cat->{bundles} } );
    _fail( 'unknown bundle "'.$name.'" in '.$source.( length $known ? ' (available bundles: '.$known.')' : '' ) );
  }
  my $e;
  return $e->{foreign} if eval { $e = expand_bundle( $cat, $name ); 1 };
  my $err = $@;
  die $err unless blessed $err && $err->isa('Skilletor::Error::Bundle');
  _fail( $source.': '.$err->message );
}

#### uninstall #################################################################

# Remove explicit entries from one config, then sync. Plan every removal first: an item with no
# explicit entry is an error (naming a covering wildcard or bundle, another type, or the other
# scope) and leaves the config untouched. Hints name covering entries that remain after a valid
# explicit removal.
sub uninstall {
  my ( $engine, %args ) = @_;
  my $project    = $args{project} ? 1 : 0;
  my $path       = config_path( $engine, $project );
  my $scope_name = $project ? 'project' : 'user';
  my $lock       = read_lock( path_join( dirname($path), 'skilletor.lock.json' ) );
  my @parsed     = map { +{ spec => $_, %{ _parse_item_spec($_) } } } @{ $args{items} };

  my ( @errors, @hints );
  my $where        = 'the '.$scope_name.' config';
  my $bundles_here = Skilletor::Config->bundle_entries($path);
  for my $p (@parsed) {
    my $explicit = $p->{bundle} ? []
      : Skilletor::Config->find_install_entries( $path, $p->{name}, $p->{source}, $p->{type} );
    my $bundle_hit = grep { $_->{name} eq $p->{name} && $_->{source} eq $p->{source} } @$bundles_here;
    # Without a prefix, a name declared only as a bundle here is that bundle (spec §15.5).
    if ( !$p->{bundle} && !$p->{type} && index( $p->{name}, WILDCARD ) < 0 && $bundle_hit ) {
      if (@$explicit) {
        push @errors, $p->{name}.'@'.$p->{source}.' is ambiguous in '.$where.': it names a bundle and '
          .join( ', ', map { $_->{type}.':'.$p->{name}.'@'.$p->{source} } @$explicit )
          .'; use a prefix (bundle:'.$p->{name}.'@'.$p->{source}.')';
      }
      else {
        $p->{bundle} = 1;
      }
      next;
    }
    if ( $p->{bundle} ) {
      push @errors, 'bundle:'.$p->{name}.'@'.$p->{source}.' is not declared in '.$where.' ('.$path.')'
        ._bundle_elsewhere( $engine, $p, $project ) unless $bundle_hit;
      next;
    }
    my $label = ( $p->{type} ? $p->{type}.':' : '' ).$p->{name}.'@'.$p->{source};
    my $cover = index( $p->{name}, WILDCARD ) >= 0
      ? { source => $p->{source}, wilds => [], bundles => [], confirmed => 0 }
      : _covering( $path, $lock, $bundles_here, $p->{name}, $p->{source}, $p->{type}, [ map { $_->{type} } @$explicit ] );
    my $text = _cover_text($cover);
    if ( !@$explicit ) {
      if ( length $text && $cover->{confirmed} ) {
        push @errors, $label.' is not declared explicitly; it is installed by the '.$text.' in '.$where.'. To drop it, '
          ._way_out( $cover, $project );
      }
      elsif ( length $text ) {
        push @errors, $label.' is not declared in '.$where.' ('.$path.'); the '.$text
          .' there installs every matching item of its type from '.$p->{source}.', so if '.$p->{source}.' offers it: '
          ._way_out( $cover, $project );
      }
      else {
        push @errors, $label.' is not declared in '.$where.' ('.$path.')'
          ._declared_elsewhere( $engine, $path, $p, $project );
      }
    }
    elsif ( length $text ) {
      push @hints, $label.' removed, but the '.$text.' in '.$where.' still installs it on the next sync. To drop it, '
        ._way_out( $cover, $project );
    }
  }
  _fail( join "\n", @errors ) if @errors;

  for my $p (@parsed) {
    if ( $p->{bundle} ) {
      Skilletor::Config->remove_bundle_entries( $path, $p->{name}, $p->{source} );
    }
    else {
      Skilletor::Config->remove_install_entries( $path, $p->{name}, $p->{source}, $p->{type} );
    }
  }
  return { report => $engine->sync, hints => \@hints };
}

# Wildcards and bundles in one config that install name@source. A wildcard's type comes from the
# prefix, else from explicit entries being removed plus the scope's lock; if neither knows it,
# every matching wildcard of the source counts. A bundle counts when the lock records it in the
# item's `via` (spec §15.5).
sub _covering {
  my ( $path, $lock, $bundles_here, $name, $source, $type, $explicit_types ) = @_;
  my @found = map { +{ type => $_->{type}, pattern => $_->{pattern} } }
    grep { matches_pattern( $_->{pattern}, $name ) }
    @{ Skilletor::Config->find_wildcard_entries( $path, $source, $type ) };
  # Any target's entry counts (claude `skills/x`, codex `codex:skills/x`), its name ignoring case.
  my $locked = sub {
    my ( $wanted_type ) = @_;
    return [ grep {
      my $entry = $lock->{$_};
      my $key   = parse_lock_key($_);
      js_type($entry) eq 'object'
        && name_key( $key->{name} ) eq name_key($name)
        && ( !$wanted_type || $key->{type} eq $wanted_type )
        && defined $entry->{source} && $entry->{source} eq $source;
    } keys %$lock ];
  };
  my $in_lock = sub { @{ $locked->( $_[0] ) } ? 1 : 0 };
  my %labels = map { ( Skilletor::Resolver->bundle_label($_) => 1 ) } @$bundles_here;
  my ( @bundles, %seen );
  for my $key ( @{ $locked->($type) } ) {
    for my $via ( @{ $lock->{$key}{via} // [] } ) {
      push @bundles, $via if $labels{$via} && !$seen{$via}++;
    }
  }
  my $confirmed = @bundles || grep { $in_lock->( $_->{type} ) } @found;
  return { source => $source, wilds => \@found, bundles => \@bundles, confirmed => $confirmed ? 1 : 0 } if $type;
  my @known = grep {
    my $wild = $_;
    ( grep { $_ eq $wild->{type} } @$explicit_types ) || $in_lock->( $wild->{type} );
  } @found;
  return {
    source    => $source,
    wilds     => @known || @$explicit_types ? \@known : \@found,
    bundles   => \@bundles,
    confirmed => $confirmed ? 1 : 0,
  };
}

# The covering wildcards as written with their type, then the bundles.
sub _cover_entries {
  my ( $cover ) = @_;
  return ( map { $_->{type}.':'.$_->{pattern}.'@'.$cover->{source} } @{ $cover->{wilds} } ), @{ $cover->{bundles} };
}

sub _cover_text {
  my ( $cover ) = @_;
  my @wilds = map { $_->{type}.':'.$_->{pattern}.'@'.$cover->{source} } @{ $cover->{wilds} };
  my @parts;
  push @parts, ( @wilds == 1 ? 'wildcard ' : 'wildcards ' ).join( ', ', @wilds ) if @wilds;
  push @parts, ( @{ $cover->{bundles} } == 1 ? 'bundle ' : 'bundles ' ).join( ', ', @{ $cover->{bundles} } )
    if @{ $cover->{bundles} };
  return join ' and ', @parts;
}

sub _way_out {
  my ( $cover, $project ) = @_;
  my $flag = $project ? ' --project' : '';
  my $cmds = join ' or ', map { "skilletor uninstall '".$_."'".$flag } _cover_entries($cover);
  my $what = !@{ $cover->{bundles} } ? 'the wildcard' : !@{ $cover->{wilds} } ? 'the bundle' : 'them';
  return 'uninstall '.$what.' ('.$cmds.'), or keep it and gate the item via vars '
    .'if its template renders empty for some value (an empty render is skipped).';
}

# Where else a bundle is declared: the other scope's config.
sub _bundle_elsewhere {
  my ( $engine, $p, $project ) = @_;
  return '' if !$project && !defined $engine->project_dir_of;
  my $hit = grep { $_->{name} eq $p->{name} && $_->{source} eq $p->{source} }
    @{ Skilletor::Config->bundle_entries( config_path( $engine, !$project ) ) };
  return '' unless $hit;
  return $project ? '; the user config declares it (run without --project)'
    : '; the project config declares it (use --project)';
}

# Where else the item is declared: under another type here, or in the other scope's config.
sub _declared_elsewhere {
  my ( $engine, $path, $p, $project ) = @_;
  if ( $p->{type} ) {
    my @other = map { $_->{type}.':'.$p->{name}.'@'.$p->{source} }
      @{ Skilletor::Config->find_install_entries( $path, $p->{name}, $p->{source} ) };
    return '; it is declared as '.join( ', ', @other ) if @other;
  }
  return '' if !$project && !defined $engine->project_dir_of;
  my $other_path = config_path( $engine, !$project );
  my $hit = @{ Skilletor::Config->find_install_entries( $other_path, $p->{name}, $p->{source}, $p->{type} ) }
    || ( index( $p->{name}, WILDCARD ) < 0
      && grep { matches_pattern( $_->{pattern}, $p->{name} ) }
        @{ Skilletor::Config->find_wildcard_entries( $other_path, $p->{source}, $p->{type} ) } );
  return '' unless $hit;
  return $project ? '; the user config declares it (run without --project)'
    : '; the project config declares it (use --project)';
}

#### trust #####################################################################

sub trust {
  my ( $engine, $name ) = @_;
  my $src = _load($engine)->source($name) or _fail( 'unknown source: '.$name );
  my $backend = Skilletor::Backend->resolve( $src, $engine->home );
  Skilletor::State->new( root => $engine->state_root )->trust( $name, $backend );
  return js_ordered( name => $name, kind => $backend->{kind}, url => $backend->{address} );
}

# Trust a source definition just written by `add` (or a bundle's missing source): the backend it
# names, normalized by the one resolver (spec §4.3).
sub _trust_def {
  my ( $engine, $name, $def ) = @_;
  Skilletor::State->new( root => $engine->state_root )
    ->trust( $name, Skilletor::Backend->resolve( { name => $name, %$def, origins => {} }, $engine->home ) );
}

#### helpers ###################################################################

# `[type:]name@source`, `type:pattern@source` or `bundle:name@source` (spec §7, §15.5):
# { type, bundle, name, source }, `type` and `bundle` only when given. Uninstall (k179) reads its
# items the same way.
sub _parse_item_spec {
  my ( $spec ) = @_;
  my $at = rindex $spec, '@';
  _fail( 'item "'.$spec.'" must be name@source (or type:name@source)' ) if $at <= 0 || $at == length($spec) - 1;
  my $source = substr $spec, $at + 1;
  my $name   = substr $spec, 0, $at;
  my %out;
  my $colon = index $name, ':';
  if ( $colon != -1 ) {
    my $prefix = substr $name, 0, $colon;
    if    ( $prefix eq 'bundle' )                                         { $out{bundle} = 1 }
    elsif ( $prefix eq 'skill' || $prefix eq 'agent' || $prefix eq 'rule' ) { $out{type}   = $prefix }
    else                                                                  { _fail( 'unknown type prefix "'.$prefix.'" in "'.$spec.'"' ) }
    $name = substr $name, $colon + 1;
  }
  _fail( 'item "'.$spec.'" has an empty name' ) if $name eq '';
  if ( $out{bundle} ) {
    _fail( '"'.$spec.'": patterns over bundle names are not supported' ) if index( $name, WILDCARD ) >= 0;
    return { bundle => 1, name => $name, source => $source };
  }
  if ( index( $name, WILDCARD ) >= 0 && !$out{type} ) {
    _fail( 'wildcard "'.$spec.'" needs a type prefix: rule:'.$name.'@'.$source.', skill:'.$name.'@'.$source
        .' or agent:'.$name.'@'.$source );
  }
  return { %out, name => $name, source => $source };
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Skilletor::Commands - The CLI's config commands – add, trust, source list, source remove, available, install, uninstall – after the reference's commands.ts

=head1 VERSION

version 0.008000

=head1 SYNOPSIS

  use Skilletor::Commands qw( add available install source_list source_remove trust uninstall );

  my $engine = Skilletor::Engine->new( home => $ENV{HOME}, project_dir => $project );
  my $added  = add( $engine, spec => 'Getty/skills', project => 0 );   # { name, def, kept, report }
  my $list   = source_list($engine);                    # [ { name, def, origin }, ... ]
  my $r      = trust( $engine, 'team' );                 # { name, kind, url }
  my $report = source_remove( $engine, name => 'extra', project => 0, force => 0 );
  my $items  = available( $engine, source => 'team' );   # [ { type, name, description, source, installed, ... }, ... ]
  $report    = install( $engine, items => ['rule:*@team', 'bundle:perl@team'], project => 0, prompt => $prompt );
  my $result = uninstall( $engine, items => ['rule:old@team'], project => 0 ); # { report, hints }

=head1 DESCRIPTION

The commands of the CLI that read or edit the config, after the reference's
F<src/commands.ts>: the same checks in the same order, the same messages, the
config files written by L<Skilletor::Config>'s edit operations (two-space
JSON, the file's key order kept); an edit is followed by the engine's sync,
whose report the command returns. C<available> edits nothing: it reads the
sources under the sync lock, as a sync does; C<install> plans its edits under
it; C<uninstall> validates every removal before editing. Each takes the L<Skilletor::Engine> the CLI
runs on as its context – home, project dir, C<CLAUDE_CONFIG_DIR>, state root –
as the reference's take its C<CommandContext>.

A refusal is a L<Skilletor::Error::Command>, a spec that does not resolve a
L<Skilletor::Error::Spec>, a config file load refuses a
L<Skilletor::Error::Config>; none of them changes anything.

=head2 add

  my $r = add( $engine, spec => $spec, name => $name, project => $bool, probe => $probe );

Adds the source C<$spec> resolves to (L<Skilletor::Spec/resolve_spec>) to the
user config, or the project config with C<project>, under C<name> or the name
the spec derives, trusts it for the backend it names and syncs. Returns C<<
{ name, def, kept, report } >>: C<def> the source's fields as written, in
their order, C<report> the sync's (its C<error> set when that sync stopped at a
config error; the edit stays).

It never replaces a source (k101): when the config already declares the name
with the same backend and address – git and url as one source identity, a
local path as the directory it names – that entry is kept as it is (C<kept>
set, C<def> its fields), trusted and synced. It throws, before anything is
written or trusted, for a name config load would refuse (k95), a definition it
would refuse (k110: a C<url> not C<https://>), no project scope with
C<project>, a taken name with another address, a spec's ref (k119) or path
(k126) the kept entry does not have, and a kept entry load would refuse (k116).

A generic host (C<host.tld[/path]>) is probed through C<probe>, by default
L<Skilletor::Probe/make_probe>'s.

=head2 config_path

  my $file = config_path( $engine, $project );

The config file an edit writes: the user config (C<< <CLAUDE_CONFIG_DIR or
~/.claude>/skilletor.json >>), or with C<$project> the project's
F<.claude/skilletor.json>. With C<$project> and no project scope – the project
dir is the home dir, or there is none – it throws, saying which.

=head2 source_list

  my $list = source_list($engine);

Every source as the project scope sees it, in the merged map's order: C<<
{ name, def, origin } >>, C<def> the merged fields in the order C<git>,
C<ref>, C<url>, C<local>, C<path>, C<origin> that of the backend author mode
would use (L<Skilletor::Backend/resolve>).

=head2 source_remove

  my $report = source_remove( $engine, name => $name, project => $bool, force => $bool );

Removes source C<$name> from the user config, or the project config with
C<project>, then syncs and returns the sync's report (its C<error> set when
that sync stopped at a config error; the edit stays). It throws, changing
nothing, when that config does not declare the name (naming where else it is
declared, k114), when the entry gives the source its only backend and another
file keeps an entry for it without one (k137), when a config file still fails
to load with the entry unchecked (k120), and – without C<force> – when an
entry, a wildcard or a bundle of either scope still uses the source.

=head2 available

  my $items = available( $engine, source => $name );

What the trusted sources offer, or source C<$name> alone: each source resolved
– fetched into the cache, as a sync would – and scanned, holding the sync lock
(L<Skilletor::State/with_lock>; the caches' leftovers swept first, as a sync
does). A source is read by the definition C<install> would use: the user
config's for a user source, the merged one for a source only a project
declares. A source not trusted is skipped, even by name.

Returns a list of C<< { type, name, description, source, installed, error } >>,
in source order, each source's items first, then its bundles. C<description>
is there when the item has one, C<error> – why it cannot be built (spec §4.1)
– when it cannot.
C<installed> (a JSON boolean): an item that an entry of either scope declares
or that a lock of either scope holds for that source, under any target,
unless it rendered empty there. A bundle is C<type> C<bundle>, C<installed>
when either scope's config declares it, with C<members> – its expanded items
as C<type:name> and its entries of other sources as written, sorted – and
C<vars>, its own var defaults; or C<error>, why it cannot be expanded (spec
§15.4).

It throws a L<Skilletor::Error::Command> for a name no source has, a
L<Skilletor::Error::Config> for a config file load refuses, and passes on what
a lock read, a resolve or a scan throws; the CLI then prints nothing else.

=head2 install

  my $report = install( $engine, items => \@items, project => $bool, prompt => $prompt );

Adds each item to the user config, or the project config with C<project>,
then syncs and returns the sync's report (its C<error> set when that sync
stopped at a config error; the edits stay). An item is
C<[type:]name@source>, C<type:pattern@source> with a C<*> (a wildcard entry,
expanded by the sync; C<*> alone needs a type) or C<bundle:name@source>; a
bare C<name@source> that no item of the source has but a bundle does is that
bundle (spec §15.5). The source is the one the target scope sees: the user
config's for the user scope, the merged one for the project's.

Every item is checked before anything is written, holding the sync lock
(L<Skilletor::State/with_lock>; the caches' leftovers swept first), the
source resolved and scanned as a sync would; the lock is free again for the
questions and the sync, which takes it itself. It throws a
L<Skilletor::Error::Command>, changing nothing, for an item it cannot read, no
project scope with C<project>, an unknown or untrusted source, an unknown or
ambiguous name, an item with an error of its own (spec §4.1), and a bundle
that does not exist or does not expand (spec §15.4: an entry address config
load would refuse, k115, is such an error); a config file load refuses is a
L<Skilletor::Error::Config>.

A bundle's entries of other sources whose address no configured source the
target scope sees serves are missing sources (spec §15.6), each identity once.
Without C<prompt> the command throws, naming the C<skilletor add> commands
that would add them. With it each is asked for: C<prompt> is called with the
question – C<bundle E<lt>nameE<gt> needs a source you don't have yet:
E<lt>specE<gt> → E<lt>addressE<gt> — add it as [E<lt>nameE<gt>]? (name, or n
to skip)> – and returns the answer: empty takes the proposed name, C<n> or
C<no> skips the source (its members then a warning of the sync), any other is
the name, asked again with a note before the question when config load would
refuse it (k95) or a source with another address – or an entry of the config
written, whatever its address (k102) – has it. The proposed name is the
address's derived one, else that with C<-2>, C<-3>, … An added source is
written after the items and trusted as L</add> trusts it.

=head2 uninstall

  my $r = uninstall( $engine, items => \@items, project => $bool );
  # { report => $sync_report, hints => \@warnings }

Removes explicit item, wildcard or bundle entries from the user config, or the
project config with C<project>, then syncs. A type prefix restricts removal to
that type; a bare item name removes it from every type. A bare name that only a
bundle entry has removes that bundle, while a name held both as an item and a
bundle is ambiguous. Returns the sync's C<report> and one C<hints> line per
removed explicit item a wildcard or bundle in the same config still installs.

Every requested removal is checked before any edit. An entry not declared
explicitly throws a L<Skilletor::Error::Command>, naming its covering wildcard
or bundle when the scope's lock confirms it, a matching wildcard conditionally
when no installed item confirms it, another type in the same config, or the
other scope and the needed C<--project> choice. The message gives the command
that removes a covering entry and the alternative of gating a template to
render empty. A failure leaves the config byte-identical. A sync error after a
valid edit is returned in C<report>; the edit stays.

=head2 trust

  my $r = trust( $engine, $name );

Trusts source C<$name> of the merged map for the backend it would use now –
its kind and address, a C<local> one as an absolute path (the real path when
the directory exists) – in the state root's
F<trust.json>, replacing an earlier entry. Returns C<< { name, kind, url } >>;
an unknown name throws.

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
