package Skilletor::Config;
# ABSTRACT: Load, merge and validate the user, project and local skilletor config

use Moo;
use Carp qw( croak );
use Errno ();
use JSON::MaybeXS ();
use Skilletor::Entry qw(
  HARNESSES WILDCARD SOURCE_NAME_RULE INSTALL_KEYS INSTALL_KEY_OF BUNDLES_KEY ITEM_TYPES
  name_key is_source_name is_pattern parse_entry parse_bundle_entry seen_key
);
use Skilletor::Error::Config;
use Skilletor::Error::JSON;
use Skilletor::FSUtil qw( read_text inner_segments path_join write_text );
use Skilletor::JSON qw( js_parse js_stringify js_ordered js_type );
use namespace::clean;

our $VERSION = '0.001';

my @ALLOWED_KEYS = qw( sources install vars gitignore claudeSettings checkInterval targets );
my %ALLOWED_KEY  = map { $_ => 1 } @ALLOWED_KEYS;
my %SOURCE_KEY   = map { $_ => 1 } qw( git ref url local path );
my @BACKEND_KINDS = qw( git url local );
# The order the reference writes a source definition's fields in (commands.ts pickDef).
my @SOURCE_FIELD_ORDER = qw( git ref url local path );
# What `git check-ref-format` forbids character by character.
my $NOT_IN_REF = qr/[\x00-\x20\x7f~^:?*[\\]|\.\.|\@\{/;

has home => (
  is       => 'ro',
  required => 1,
);

# `CLAUDE_CONFIG_DIR` (k145): the user config's dir; unset or empty means `<home>/.claude`.
has claude_config_dir => (
  is => 'ro',
);

has project_dir => (
  is => 'ro',
);

has unchecked => (
  is => 'ro',
);

has user_path => (
  is       => 'lazy',
  init_arg => undef,
);

sub _build_user_path {
  my ( $self ) = @_;
  my $cd = $self->claude_config_dir;
  return path_join( ( defined $cd && length $cd ) ? $cd : path_join( $self->home, '.claude' ), 'skilletor.json' );
}

has project_path => (
  is       => 'lazy',
  init_arg => undef,
);

sub _build_project_path {
  my ( $self ) = @_;
  return defined $self->project_dir ? path_join( $self->project_dir, '.claude', 'skilletor.json' ) : undef;
}

has local_path => (
  is       => 'lazy',
  init_arg => undef,
);

sub _build_local_path {
  my ( $self ) = @_;
  return defined $self->project_dir ? path_join( $self->project_dir, '.claude', 'skilletor.local.json' ) : undef;
}

has _loaded => (
  is       => 'lazy',
  init_arg => undef,
);

sub BUILD { $_[0]->_loaded }

sub load {
  my ( $class, %args ) = @_;
  return $class->new(%args);
}

sub has_project      { defined $_[0]->project_dir ? 1 : 0 }
sub check_interval   { $_[0]->_loaded->{checkInterval} }
sub user             { $_[0]->_loaded->{user} }
sub project          { $_[0]->_loaded->{project} }
sub sources          { [ _map_values( $_[0]->_loaded->{sources} ) ] }
sub source_names     { _map_names( $_[0]->_loaded->{sources} ) }
sub user_sources     { [ _map_values( $_[0]->_loaded->{userSources} ) ] }
sub user_source_names { _map_names( $_[0]->_loaded->{userSources} ) }

sub source {
  my ( $self, $name ) = @_;
  return _map_get( $self->_loaded->{sources}, $name );
}

sub user_source {
  my ( $self, $name ) = @_;
  return _map_get( $self->_loaded->{userSources}, $name );
}

# The sources a scope resolves against: the user config's alone for the user scope, the
# merged map for the project scope (spec §3).
sub sources_of {
  my ( $self, $scope ) = @_;
  return $scope eq 'user' ? $self->user_sources : $self->sources;
}

sub source_of {
  my ( $self, $scope, $name ) = @_;
  return $scope eq 'user' ? $self->user_source($name) : $self->source($name);
}

sub scope {
  my ( $self, $scope ) = @_;
  return $scope eq 'user' ? $self->user : $self->project;
}

# The reference's LoadedConfig as one JSON-shaped value; its Maps as objects in Map order.
sub to_data {
  my ( $self ) = @_;
  my $l = $self->_loaded;
  my $map = sub {
    my ( $m ) = @_;
    # A Map keeps insertion order; an object would move index keys first. Pairs keep it.
    return [ map { [ $_, _map_get( $m, $_ ) ] } _map_names($m) ];
  };
  return {
    sources       => $map->( $l->{sources} ),
    checkInterval => $l->{checkInterval},
    user          => $l->{user},
    ( $l->{project} ? ( project => $l->{project} ) : () ),
    userSources   => $map->( $l->{userSources} ),
  };
}

#### Insertion-ordered maps (JavaScript Map) ###########################

sub _map_new    { { order => [], by => {} } }
sub _map_has    { exists $_[0]{by}{ $_[1] } }
sub _map_get    { $_[0]{by}{ $_[1] } }
sub _map_names  { @{ $_[0]{order} } }
sub _map_values { map { $_[0]{by}{$_} } @{ $_[0]{order} } }

sub _map_set {
  my ( $m, $k, $v ) = @_;
  push @{ $m->{order} }, $k unless exists $m->{by}{$k};
  $m->{by}{$k} = $v;
}

sub _map_delete {
  my ( $m, $k ) = @_;
  return unless exists $m->{by}{$k};
  delete $m->{by}{$k};
  $m->{order} = [ grep { $_ ne $k } @{ $m->{order} } ];
}

#### Reading ###########################################################

sub _fail { Skilletor::Error::Config->throw( $_[1] ) }

# Node's message for a failed readFileSync, for the reasons a config file meets.
sub _read_error {
  my ( $self, $file, $errno ) = @_;
  local $! = $errno;
  return 'EACCES: permission denied, open \''.$file.'\'' if $!{EACCES};
  return 'ENOTDIR: not a directory, open \''.$file.'\'' if $!{ENOTDIR};
  return 'EISDIR: illegal operation on a directory, read' if $!{EISDIR};
  return 'ELOOP: too many symbolic links encountered, open \''.$file.'\'' if $!{ELOOP};
  return "$!";
}

# One config file: parsed and its top-level keys checked; a missing file is an empty object.
sub _read_config_file {
  my ( $self, $file ) = @_;
  my $text;
  if ( -d $file ) {
    $self->_fail( $file.': cannot read config (EISDIR: illegal operation on a directory, read)' );
  }
  if ( open my $fh, '<:raw', $file ) {
    local $/;
    my $bytes = <$fh>;
    close $fh;
    $text = Skilletor::FSUtil::decode_utf8_lossy( $bytes // '' );
  }
  else {
    return js_ordered() if $!{ENOENT};
    $self->_fail( $file.': cannot read config ('.$self->_read_error( $file, 0 + $! ).')' );
  }
  my $value;
  unless ( eval { $value = js_parse($text); 1 } ) {
    my $err = $@;
    $self->_fail( $file.': invalid JSON ('.( ref $err && $err->can('message') ? $err->message : "$err" ).')' );
  }
  $self->_fail( $file.': top level must be a JSON object' ) unless js_type($value) eq 'object';
  for my $key ( keys %$value ) {
    next if $ALLOWED_KEY{$key};
    $self->_fail( $file.': unknown key "'.$key.'" (allowed: '.join( ', ', @ALLOWED_KEYS ).')' );
  }
  return $value;
}

sub _as_object {
  my ( $self, $obj, $key, $file, $where ) = @_;
  return js_ordered() unless exists $obj->{$key};
  my $value = $obj->{$key};
  $self->_fail( $file.': '.$where.' must be an object' ) unless js_type($value) eq 'object';
  return $value;
}

sub _has_backend {
  my ( $src ) = @_;
  return ( exists $src->{git} || exists $src->{url} || exists $src->{local} ) ? 1 : 0;
}

sub _parse_sources {
  my ( $self, $obj, $file, $origin, $unchecked ) = @_;
  my $sources = _map_new();
  my $raw = $self->_as_object( $obj, 'sources', $file, 'sources' );
  for my $name ( keys %$raw ) {
    if ( defined $unchecked && $name eq $unchecked ) {
      _map_set( $sources, $name, { name => $name, origins => {} } );
      next;
    }
    unless ( is_source_name($name) ) {
      $self->_fail( $file.': source name '.js_stringify($name).' is not valid ('.SOURCE_NAME_RULE.')' );
    }
    # A backend may come from another file of the merge: the loader checks that.
    my $fields = $self->source_fields( $raw->{$name}, $file.': sources.'.$name, 0 );
    my $src = { name => $name, origins => {}, %$fields };
    for my $kind (@BACKEND_KINDS) {
      $src->{origins}{$kind} = $origin if exists $src->{$kind};
    }
    _map_set( $sources, $name, $src );
  }
  return $sources;
}

sub source_fields {
  my ( $self, $def, $at, $needs_backend ) = @_;
  $needs_backend //= 1;
  $self->_fail( $at.' must be an object' ) unless js_type($def) eq 'object';
  for my $key ( keys %$def ) {
    $self->_fail( $at.': unknown key "'.$key.'"' ) unless $SOURCE_KEY{$key};
  }
  my %src;
  $src{git} = $self->_git_field( $self->_string_field( $def->{git}, 'git', $at ), 'git', $at ) if exists $def->{git};
  # "ref": null is no ref: in a file of the merge it unsets a lower file's.
  if ( exists $def->{ref} && defined $def->{ref} ) {
    $src{ref} = $self->_git_field( $self->_string_field( $def->{ref}, 'ref', $at ), 'ref', $at );
  }
  $src{local} = $self->_string_field( $def->{local}, 'local', $at ) if exists $def->{local};
  if ( exists $def->{url} ) {
    my $url = $def->{url};
    unless ( js_type($url) eq 'string' && $url =~ m{\Ahttps://} ) {
      $self->_fail( $at.'.url '.js_stringify($url).' must be an https:// URL' );
    }
    $src{url} = $url;
  }
  $src{path} = $self->_path_field( $def->{path}, $at ) if exists $def->{path};
  if ( $needs_backend && !_has_backend( \%src ) ) {
    $self->_fail( $at.' needs one of "git", "url" or "local"' );
  }
  return \%src;
}

sub _string_field {
  my ( $self, $value, $key, $at ) = @_;
  my $where = $at.'.'.$key.' '.js_stringify($value);
  $self->_fail( $where.' must be a string' ) unless js_type($value) eq 'string';
  if ( $value eq '' ) {
    $self->_fail( $where.' must not be empty'.( $key eq 'ref' ? ' (omit "ref" for the remote\'s HEAD)' : '' ) );
  }
  return $value;
}

sub _git_field {
  my ( $self, $value, $key, $at ) = @_;
  my $where = $at.'.'.$key.' '.js_stringify($value);
  $self->_fail( $where.' must not start with "-" (git would read it as an option)' ) if $value =~ /\A-/;
  if ( $key eq 'ref' && $value =~ $NOT_IN_REF ) {
    $self->_fail( $where.' is not a git ref name (no whitespace, control characters, ~ ^ : ? * [ \\, ".." or "@{")' );
  }
  return $value;
}

sub _path_field {
  my ( $self, $value, $at ) = @_;
  my $where = $at.'.path';
  my $omit  = ' (omit "path" for the default layout)';
  my $type  = js_type($value);
  unless ( $type eq 'string' || $type eq 'array' ) {
    $self->_fail( $where.' '.js_stringify($value).' must be a string or an array of strings' );
  }
  my $is_array = $type eq 'array';
  if ( $is_array ? !@$value : $value eq '' ) {
    $self->_fail( $where.' '.js_stringify($value).' must not be empty'.$omit );
  }
  my @list = $is_array ? @$value : ($value);
  for my $i ( 0 .. $#list ) {
    my $entry = $list[$i];
    my $w = $where.( $is_array ? '['.$i.']' : '' ).' '.js_stringify($entry);
    $self->_fail( $w.' must be a string' ) unless js_type($entry) eq 'string';
    $self->_fail( $w.' must not be empty' ) if $entry eq '';
    my $segments = inner_segments($entry);
    next if ref $segments;
    $self->_fail( $w.' must not be absolute (it is relative to the source root)' ) if $segments eq 'absolute';
    $self->_fail( $w.' must not contain ".."' ) if $segments eq 'dotdot';
    $self->_fail( $w.' must not be the source root (name the directories its skills lie in)' );
  }
  return $value;
}

# Merge incoming source fields over base, field by field: each backend field keeps the origin
# of its file; ref and path are replaced whole; unset_ref (the file wrote "ref": null) drops
# the ref base had.
sub _merge_source {
  my ( $base, $incoming, $unset_ref ) = @_;
  my %merged = %{ $base // $incoming };
  $merged{origins} = { %{ $base ? $base->{origins} : {} } };
  if ( exists $incoming->{ref} ) { $merged{ref} = $incoming->{ref} }
  elsif ($unset_ref)             { delete $merged{ref} }
  $merged{path} = $incoming->{path} if exists $incoming->{path};
  for my $kind (@BACKEND_KINDS) {
    next unless exists $incoming->{$kind};
    $merged{$kind} = $incoming->{$kind};
    $merged{origins}{$kind} = $incoming->{origins}{$kind};
  }
  return \%merged;
}

sub _override_use {
  my ( $self, $file, $entry, $source ) = @_;
  return $file.': user install "'.$entry.'" references source "'.$source.'", which has no "git", "url" or "local" '
    .'in this file (user-scope items are built from the user config\'s sources alone)';
}

sub _parse_install {
  my ( $self, $obj, $file, $scope, $known, $overrides ) = @_;
  $overrides //= {};
  my $install = $self->_as_object( $obj, 'install', $file, 'install' );
  my %install_keys = INSTALL_KEYS;
  for my $key ( keys %$install ) {
    next if exists $install_keys{$key} || $key eq BUNDLES_KEY;
    $self->_fail( $file.': install.'.$key.' is not a valid type (skills, agents, rules, bundles)' );
  }
  my ( @items, @wildcards, %seen );
  my @pairs = INSTALL_KEYS;
  while ( my ( $key, $type ) = splice @pairs, 0, 2 ) {
    next unless exists $install->{$key};
    my $list = $install->{$key};
    $self->_fail( $file.': install.'.$key.' must be an array' ) unless js_type($list) eq 'array';
    for my $i ( 0 .. $#$list ) {
      my $entry = $list->[$i];
      $self->_fail( $file.': install.'.$key.'['.$i.'] must be a string' ) unless js_type($entry) eq 'string';
      my $item = parse_entry( $entry, $type, $file, 'install.'.$key.'['.$i.']' );
      $self->_fail( $self->_override_use( $file, $entry, $item->{source} ) ) if $overrides->{ $item->{source} };
      unless ( _map_has( $known, $item->{source} ) ) {
        $self->_fail( $file.': '.$scope.' install "'.$entry.'" references unknown source "'.$item->{source}.'"' );
      }
      my $target_key = seen_key($item);
      if ( defined( my $prev = $seen{$target_key} ) ) {
        $self->_fail( $file.': duplicate '.$item->{type}.' target "'.$item->{name}.'" declared as '.$prev.' and '.$entry );
      }
      $seen{$target_key} = $entry;
      if ( is_pattern( $item->{name} ) ) {
        push @wildcards, { type => $item->{type}, source => $item->{source}, pattern => $item->{name}, raw => $entry };
      }
      else {
        push @items, $item;
      }
    }
  }
  my $bundles = $self->_parse_bundles( $install, $file, $scope, $known, $overrides );
  return { install => \@items, wildcards => \@wildcards, bundles => $bundles };
}

sub _parse_bundles {
  my ( $self, $install, $file, $scope, $known, $overrides ) = @_;
  return [] unless exists $install->{ BUNDLES_KEY() };
  my $list = $install->{ BUNDLES_KEY() };
  $self->_fail( $file.': install.'.BUNDLES_KEY.' must be an array' ) unless js_type($list) eq 'array';
  my @out;
  for my $i ( 0 .. $#$list ) {
    my $entry = $list->[$i];
    my $where = 'install.'.BUNDLES_KEY.'['.$i.']';
    $self->_fail( $file.': '.$where.' must be a string' ) unless js_type($entry) eq 'string';
    my $b = parse_bundle_entry( $entry, $file, $where );
    $self->_fail( $self->_override_use( $file, $entry, $b->{source} ) ) if $overrides->{ $b->{source} };
    unless ( _map_has( $known, $b->{source} ) ) {
      $self->_fail( $file.': '.$scope.' install "'.$entry.'" references unknown source "'.$b->{source}.'"' );
    }
    push @out, $b;
  }
  return $self->_dedupe_bundles( \@out, [], $file );
}

sub _dedupe_bundles {
  my ( $self, $a, $b, $file ) = @_;
  my %seen;
  for my $x ( @$a, @$b ) {
    my $key = $x->{name}.'@'.$x->{source};
    if ( defined( my $prev = $seen{$key} ) ) {
      $self->_fail( $file.': duplicate bundle "'.$key.'" declared as '.$prev.' and '.$x->{raw} );
    }
    $seen{$key} = $x->{raw};
  }
  return [ @$a, @$b ];
}

sub _dedupe_across {
  my ( $self, $a, $b, $file ) = @_;
  my %seen;
  for my $item ( @$a, @$b ) {
    my $key = seen_key($item);
    if ( defined( my $prev = $seen{$key} ) ) {
      $self->_fail( $file.': duplicate '.$item->{type}.' target "'.$item->{name}.'" declared as '.$prev.' and '.$item->{raw} );
    }
    $seen{$key} = $item->{raw};
  }
  return [ @$a, @$b ];
}

sub _dedupe_wildcards {
  my ( $self, $a, $b, $file ) = @_;
  my %seen;
  for my $w ( @$a, @$b ) {
    my $key = seen_key( { type => $w->{type}, name => $w->{pattern}, source => $w->{source} } );
    if ( defined( my $prev = $seen{$key} ) ) {
      $self->_fail( $file.': duplicate '.$w->{type}.' wildcard for "'.$w->{source}.'" declared as '.$prev.' and '.$w->{raw} );
    }
    $seen{$key} = $w->{raw};
  }
  return [ @$a, @$b ];
}

sub _merge_vars {
  my ( @objs ) = @_;
  my $out = js_ordered();
  for my $o (@objs) {
    $out->{$_} = $o->{$_} for keys %$o;
  }
  return $out;
}

sub _targets_of {
  my ( $self, $obj, $file ) = @_;
  return undef unless exists $obj->{targets};
  my $value   = $obj->{targets};
  my $allowed = join ', ', HARNESSES;
  my %known   = map { $_ => 1 } HARNESSES;
  unless ( js_type($value) eq 'array' && @$value ) {
    $self->_fail( $file.': "targets" must be a non-empty array (of '.$allowed.')' );
  }
  my @out;
  for my $v (@$value) {
    unless ( js_type($v) eq 'string' && $known{$v} ) {
      $self->_fail( $file.': "targets" has unknown harness '.js_stringify($v).' (allowed: '.$allowed.')' );
    }
    $self->_fail( $file.': "targets" lists "'.$v.'" twice' ) if grep { $_ eq $v } @out;
    push @out, $v;
  }
  return \@out;
}

sub _number_or {
  my ( $self, $obj, $key, $fallback, $file ) = @_;
  return $fallback unless exists $obj->{$key};
  my $value = $obj->{$key};
  unless ( js_type($value) eq 'number' && $value == $value && $value != 9**9**9 && $value != -9**9**9 ) {
    $self->_fail( $file.': "'.$key.'" must be a number' );
  }
  return $value;
}

# boolOr: $present says whether the value exists at all (JavaScript's undefined).
sub _bool_or {
  my ( $self, $present, $value, $fallback, $file, $key ) = @_;
  return $fallback unless $present;
  $self->_fail( $file.': "'.$key.'" must be a boolean' ) unless js_type($value) eq 'boolean';
  return $value;
}

sub _build__loaded {
  my ( $self ) = @_;
  my $user_path    = $self->user_path;
  my $has_project  = $self->has_project;
  my $project_path = $has_project ? $self->project_path : '';
  my $local_path   = $has_project ? $self->local_path : '';

  my $user    = $self->_read_config_file($user_path);
  my $project = $has_project ? $self->_read_config_file($project_path) : js_ordered();
  my $local   = $has_project ? $self->_read_config_file($local_path) : js_ordered();
  for my $pair ( [ $project, $project_path ], [ $local, $local_path ] ) {
    my ( $obj, $p ) = @$pair;
    $self->_fail( $p.': "checkInterval" is user-only' ) if $p ne '' && exists $obj->{checkInterval};
  }

  # The user scope reads the user config's sources alone; the project scope the merged map:
  # project (base) < user < local, per field.
  my $unchecked = $self->unchecked;
  my $skip = sub {
    my ( $p ) = @_;
    return ( $unchecked && $unchecked->{path} eq $p ) ? $unchecked->{name} : undef;
  };
  my $user_sources    = $self->_parse_sources( $user, $user_path, 'user', $skip->($user_path) );
  my $project_sources = $has_project ? $self->_parse_sources( $project, $project_path, 'project', $skip->($project_path) ) : _map_new();
  my $local_sources   = $has_project ? $self->_parse_sources( $local, $local_path, 'user', $skip->($local_path) ) : _map_new();

  # "ref": null in a file unsets the ref of the files below it.
  my $null_ref = sub {
    my ( $obj, $name ) = @_;
    my $s = exists $obj->{sources} ? $obj->{sources} : undef;
    return 0 unless js_type($s) eq 'object' && exists $s->{$name};
    my $d = $s->{$name};
    return ( js_type($d) eq 'object' && exists $d->{ref} && !defined $d->{ref} ) ? 1 : 0;
  };
  my $sources = _map_new();
  _map_set( $sources, $_, _merge_source( undef, _map_get( $project_sources, $_ ) ) ) for _map_names($project_sources);
  for my $name ( _map_names($user_sources) ) {
    _map_set( $sources, $name, _merge_source( _map_get( $sources, $name ), _map_get( $user_sources, $name ), $null_ref->( $user, $name ) ) );
  }
  for my $name ( _map_names($local_sources) ) {
    _map_set( $sources, $name, _merge_source( _map_get( $sources, $name ), _map_get( $local_sources, $name ), $null_ref->( $local, $name ) ) );
  }

  # An entry without a backend only changes ref or path of a source another file of the
  # merge defines; a source no file gives one is refused, naming each file declaring it.
  for my $name ( _map_names($sources) ) {
    next if _has_backend( _map_get( $sources, $name ) );
    my @files = map { $_->[1] } grep { _map_has( $_->[0], $name ) }
      [ $project_sources, $project_path ], [ $user_sources, $user_path ], [ $local_sources, $local_path ];
    next if $unchecked && $unchecked->{name} eq $name && grep { $_ eq $unchecked->{path} } @files;
    $self->_fail( join( ' and ', @files ).': sources.'.$name.' needs one of "git", "url" or "local"; '
      .( @files == 1 ? 'no other config file gives one' : 'none of these files gives one' )
      .' (an entry without one only changes "ref" or "path" of a source another file defines)' );
  }

  # The user scope reads the user config alone, so an entry there without a backend is no
  # source of its own; a user install naming it says so.
  my %overrides;
  for my $name ( _map_names($user_sources) ) {
    my $skipped = $skip->($user_path);
    next if _has_backend( _map_get( $user_sources, $name ) ) || ( defined $skipped && $skipped eq $name );
    $overrides{$name} = 1;
    _map_delete( $user_sources, $name );
  }

  # Default 30 min. 0 (or negative) disables the in-session check; SessionStart still syncs.
  my $check_interval = $self->_number_or( $user, 'checkInterval', 1800, $user_path );

  my $true = JSON::MaybeXS::true();
  my $user_install = $self->_parse_install( $user, $user_path, 'user', $user_sources, \%overrides );
  my $user_scope = {
    scope     => 'user',
    install   => $user_install->{install},
    wildcards => $user_install->{wildcards},
    bundles   => $user_install->{bundles},
    vars      => _merge_vars( $self->_as_object( $user, 'vars', $user_path, 'vars' ) ),
  };
  $user_scope->{gitignore} = $self->_bool_or( exists $user->{gitignore}, $user->{gitignore}, $true, $user_path, 'gitignore' );
  $user_scope->{claudeSettings} =
    $self->_bool_or( exists $user->{claudeSettings}, $user->{claudeSettings}, $true, $user_path, 'claudeSettings' );
  my $user_targets = $self->_targets_of( $user, $user_path );
  $user_scope->{targets} = $user_targets if $user_targets;

  my $project_scope;
  if ($has_project) {
    # Project install can be declared in the project file and the local file.
    my $project_install = $self->_parse_install( $project, $project_path, 'project', $sources );
    my $local_install   = $self->_parse_install( $local, $local_path, 'project', $sources );
    $project_scope = {
      scope     => 'project',
      install   => $self->_dedupe_across( $project_install->{install}, $local_install->{install}, $project_path ),
      wildcards => $self->_dedupe_wildcards( $project_install->{wildcards}, $local_install->{wildcards}, $project_path ),
      bundles   => $self->_dedupe_bundles( $project_install->{bundles}, $local_install->{bundles}, $project_path ),
    };
    $project_scope->{vars} = _merge_vars(
      $self->_as_object( $user,    'vars', $user_path,    'vars' ),
      $self->_as_object( $project, 'vars', $project_path, 'vars' ),
      $self->_as_object( $local,   'vars', $local_path,   'vars' ),
    );
    # local.gitignore ?? project.gitignore: a null in the local file falls through.
    my ( $g_present, $g_value ) =
        ( exists $local->{gitignore} && defined $local->{gitignore} ) ? ( 1, $local->{gitignore} )
      : exists $project->{gitignore} ? ( 1, $project->{gitignore} )
      : ( 0, undef );
    $project_scope->{gitignore} = $self->_bool_or( $g_present, $g_value, $true, $project_path, 'gitignore' );
    # The last file that sets it: local, the committed project file, the user's.
    my $from_project = $self->_bool_or( exists $project->{claudeSettings}, $project->{claudeSettings},
      $user_scope->{claudeSettings}, $project_path, 'claudeSettings' );
    $project_scope->{claudeSettings} =
      $self->_bool_or( exists $local->{claudeSettings}, $local->{claudeSettings}, $from_project, $local_path, 'claudeSettings' );
    my $project_targets = $self->_targets_of( $project, $project_path );
    my $local_targets   = $self->_targets_of( $local, $local_path );
    my $targets = $local_targets // $project_targets;
    $project_scope->{targets} = $targets if $targets;
  }

  return {
    sources       => $sources,
    checkInterval => $check_interval,
    user          => $user_scope,
    project       => $project_scope,
    userSources   => $user_sources,
  };
}

#### Edit operations (spec §7) #########################################
#
# They change one config file, creating it if needed, written as 2-space JSON with a
# trailing newline, keeping the file's key order.

sub _load_raw {
  my ( $self, $file ) = @_;
  return js_ordered() unless -e $file;
  my $value = eval {
    my $v = js_parse( read_text($file) );
    Skilletor::Error::JSON->throw('top level must be an object') unless js_type($v) eq 'object';
    $v;
  };
  unless ($value) {
    my $err = $@;
    $self->_fail( $file.': invalid JSON ('.( ref $err && $err->can('message') ? $err->message : "$err" ).')' );
  }
  return $value;
}

sub _save_raw {
  my ( $self, $file, $cfg ) = @_;
  write_text( $file, js_stringify( $cfg, 2 )."\n" );
}

# A plain hash becomes a definition in the reference's field order; an ordered one keeps its.
sub _source_def {
  my ( $def ) = @_;
  return $def if tied %$def;
  return js_ordered( map { exists $def->{$_} ? ( $_ => $def->{$_} ) : () } @SOURCE_FIELD_ORDER );
}

sub source_entry {
  my ( $self, $file, $name ) = @_;
  my $sources = $self->_load_raw($file)->{sources};
  return undef unless js_type($sources) eq 'object' && exists $sources->{$name};
  return $sources->{$name};
}

sub add_source {
  my ( $self, $file, $name, $def ) = @_;
  my $cfg = $self->_load_raw($file);
  my $sources = defined $cfg->{sources} ? $cfg->{sources} : js_ordered();
  $sources->{$name} = _source_def($def) if js_type($sources) eq 'object';
  $cfg->{sources} = $sources;
  $self->_save_raw( $file, $cfg );
}

sub remove_source {
  my ( $self, $file, $name ) = @_;
  my $cfg = $self->_load_raw($file);
  my $sources = $cfg->{sources};
  if ( js_type($sources) eq 'object' && exists $sources->{$name} ) {
    delete $sources->{$name};
    delete $cfg->{sources} unless keys %$sources;
    $self->_save_raw( $file, $cfg );
  }
}

sub add_install_entry {
  my ( $self, $file, $type, $entry ) = @_;
  my $cfg = $self->_load_raw($file);
  my $install = defined $cfg->{install} ? $cfg->{install} : js_ordered();
  my $key  = INSTALL_KEY_OF->{$type};
  my $list = js_type( $install->{$key} ) eq 'array' ? $install->{$key} : [];
  push @$list, $entry unless grep { defined $_ && !ref $_ && $_ eq $entry } @$list;
  $install->{$key} = $list;
  $cfg->{install} = $install;
  $self->_save_raw( $file, $cfg );
}

# Does raw entry $e ([type:]name@source) declare $name (from $source, if given)? A name
# matches ignoring case; a pattern is the entry as written.
sub _entry_matches {
  my ( $e, $name, $source ) = @_;
  my $at = rindex $e, '@';
  ( my $e_name = $at > 0 ? substr( $e, 0, $at ) : $e ) =~ s/\A[a-z]+://;
  my $e_source = $at > 0 ? substr( $e, $at + 1 ) : undef;
  my $same = ( is_pattern($name) || is_pattern($e_name) ) ? $e_name eq $name : name_key($e_name) eq name_key($name);
  return $same && ( !defined $source || ( defined $e_source && $e_source eq $source ) ) ? 1 : 0;
}

sub find_install_entries {
  my ( $self, $file, $name, $source, $type ) = @_;
  my $install = $self->_load_raw($file)->{install};
  return [] unless $install;
  my @out;
  for my $t ( $type ? ($type) : (ITEM_TYPES) ) {
    my $list = js_type($install) eq 'object' ? $install->{ INSTALL_KEY_OF->{$t} } : undef;
    next unless js_type($list) eq 'array';
    for my $e (@$list) {
      push @out, { type => $t, entry => $e } if js_type($e) eq 'string' && _entry_matches( $e, $name, $source );
    }
  }
  return \@out;
}

sub remove_install_entries {
  my ( $self, $file, $name, $source, $type ) = @_;
  my $cfg = $self->_load_raw($file);
  my $install = $cfg->{install};
  return 0 unless $install && js_type($install) eq 'object';
  my $removed = 0;
  for my $key ( $type ? ( INSTALL_KEY_OF->{$type} ) : map { INSTALL_KEY_OF->{$_} } ITEM_TYPES ) {
    my $list = $install->{$key};
    next unless js_type($list) eq 'array';
    my @kept = grep {
      my $match = js_type($_) eq 'string' && _entry_matches( $_, $name, $source );
      $removed++ if $match;
      !$match;
    } @$list;
    if (@kept) { $install->{$key} = \@kept }
    else       { delete $install->{$key} }
  }
  delete $cfg->{install} unless keys %$install;
  $self->_save_raw( $file, $cfg ) if $removed;
  return $removed;
}

sub find_wildcard_entries {
  my ( $self, $file, $source, $type ) = @_;
  my $install = $self->_load_raw($file)->{install};
  return [] unless $install && js_type($install) eq 'object';
  my @out;
  for my $t ( $type ? ($type) : (ITEM_TYPES) ) {
    my $list = $install->{ INSTALL_KEY_OF->{$t} };
    next unless js_type($list) eq 'array';
    for my $e (@$list) {
      next unless js_type($e) eq 'string';
      my $at = rindex $e, '@';
      next if $at <= 0 || substr( $e, $at + 1 ) ne $source;
      ( my $pattern = substr( $e, 0, $at ) ) =~ s/\A[a-z]+://;
      push @out, { type => $t, entry => $e, pattern => $pattern } if is_pattern($pattern);
    }
  }
  return \@out;
}

sub _bundle_parts {
  my ( $e ) = @_;
  my $at = rindex $e, '@';
  return undef if $at <= 0;
  ( my $name = substr( $e, 0, $at ) ) =~ s/\Abundle://;
  return { name => $name, source => substr( $e, $at + 1 ) };
}

sub bundle_entries {
  my ( $self, $file ) = @_;
  my $install = $self->_load_raw($file)->{install};
  my $list = ( $install && js_type($install) eq 'object' ) ? $install->{ BUNDLES_KEY() } : undef;
  return [] unless js_type($list) eq 'array';
  my @out;
  for my $e (@$list) {
    my $p = js_type($e) eq 'string' ? _bundle_parts($e) : undef;
    push @out, { %$p, entry => $e } if $p;
  }
  return \@out;
}

sub add_bundle_entry {
  my ( $self, $file, $entry ) = @_;
  my $cfg = $self->_load_raw($file);
  my $install = defined $cfg->{install} ? $cfg->{install} : js_ordered();
  my $list = js_type( $install->{ BUNDLES_KEY() } ) eq 'array' ? $install->{ BUNDLES_KEY() } : [];
  my $p = _bundle_parts($entry) or croak __PACKAGE__.'->add_bundle_entry needs name@source';
  my $known = grep {
    my $q = js_type($_) eq 'string' ? _bundle_parts($_) : undef;
    $q && $q->{name} eq $p->{name} && $q->{source} eq $p->{source};
  } @$list;
  push @$list, $entry unless $known;
  $install->{ BUNDLES_KEY() } = $list;
  $cfg->{install} = $install;
  $self->_save_raw( $file, $cfg );
}

sub remove_bundle_entries {
  my ( $self, $file, $name, $source ) = @_;
  my $cfg = $self->_load_raw($file);
  my $install = $cfg->{install};
  return 0 unless $install && js_type($install) eq 'object';
  my $list = $install->{ BUNDLES_KEY() };
  return 0 unless js_type($list) eq 'array';
  my @kept = grep {
    my $p = js_type($_) eq 'string' ? _bundle_parts($_) : undef;
    !( $p && $p->{name} eq $name && $p->{source} eq $source );
  } @$list;
  my $removed = @$list - @kept;
  return 0 unless $removed;
  if (@kept) { $install->{ BUNDLES_KEY() } = \@kept }
  else       { delete $install->{ BUNDLES_KEY() } }
  delete $cfg->{install} unless keys %$install;
  $self->_save_raw( $file, $cfg );
  return $removed;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Skilletor::Config - Load, merge and validate the user, project and local skilletor config

=head1 VERSION

version 0.001

=head1 SYNOPSIS

  use Skilletor::Config;

  my $config = Skilletor::Config->load(
    home        => $ENV{HOME},
    project_dir => '/path/to/project',     # omit: user scope only
  );

  for my $item ( @{ $config->project->{install} } ) {
    my $src = $config->source( $item->{source} );
    printf "%s %s from %s\n", $item->{type}, $item->{name}, $src->{git} // $src->{url} // $src->{local};
  }

  # editing one file, as `skilletor add` / `install` do
  Skilletor::Config->add_source( $file, shared => { git => 'https://github.com/Getty/skills', ref => 'main' } );
  Skilletor::Config->add_install_entry( $file, skill => 'perl-moo@shared' );

=head1 DESCRIPTION

The port of the reference's C<config.ts> (spec §3). Three files, from an
injected home and project root:

  <home>/.claude/skilletor.json              user
  <project>/.claude/skilletor.json           project (committed)
  <project>/.claude/skilletor.local.json     local overrides

A missing file reads as an empty config. Loading happens in the constructor;
everything that can be wrong throws a L<Skilletor::Error::Config> whose message
is the reference's, and the first error reported is the one the reference
reports first – the files and keys are checked in its order.

B<Sources> merge per field: the project scope sees project E<lt> user E<lt>
local; each backend field (C<git>, C<url>, C<local>) keeps the origin of its
file (C<user> for the user and the local file, C<project> for the committed
one); C<ref> and C<path> are the last file's that gives one, and
C<"ref": null> drops a lower file's ref. An entry without a backend only
changes another file's source; a source no file gives a backend is an error.
The user scope sees the user config's sources alone.

Returned values are plain Perl data with the reference's field names, so a
dump compares with the TypeScript structures directly:

  source:   { name, git?, ref?, url?, local?, path?, origins => { git => 'user', ... } }
  item:     { type, name, source, target, raw }
  wildcard: { type, source, pattern, raw }
  bundle:   { name, source, raw }
  scope:    { scope, install, wildcards, bundles, vars, gitignore, claudeSettings, targets? }

C<gitignore> and C<claudeSettings> are L<JSON::MaybeXS> booleans; C<vars> is a
hash that keeps the merged key order.

=head2 home

Stands in for C<~>. Required: no default from C<$ENV{HOME}>, so a test or an
embedding application never reads the real home by accident.

=head2 project_dir

The project root; without it only the user scope is loaded.

=head2 unchecked

C<< { path => $file, name => $source } >>: that source of that file is declared
without being checked and without a backend (what C<source remove> needs to
load a config it is about to fix). Never synced.

=head2 user_path

C<< <home>/.claude/skilletor.json >>.

=head2 project_path

C<< <project>/.claude/skilletor.json >>, or C<undef>.

=head2 local_path

The three files; the project ones are C<undef> without a project.

=head2 load

  Skilletor::Config->load(%args);

C<new>, for reading code.

=head2 sources

The project scope's merged sources, an array in the reference's Map order.

=head2 source

  $config->source($name);

One of them by name, or C<undef>.

=head2 source_names

The merged sources' names, in Map order.

=head2 user_sources

The user scope's sources, an array in Map order.

=head2 user_source

  $config->user_source($name);

=head2 user_source_names

The user scope's sources: the user config's alone.

=head2 sources_of

The sources a scope resolves against: C<user> or C<project>.

=head2 source_of

  $config->sources_of('user');
  $config->source_of( project => $name );

The sources a scope resolves against.

=head2 check_interval

The in-session check's throttle in seconds (default 1800).

=head2 user

The user scope's config.

=head2 project

The project scope's config, or C<undef>.

=head2 scope

  $config->scope('project');

The scope configs; C<project> is C<undef> without a project dir.

=head2 has_project

True when a project dir was given.

=head2 to_data

The whole result shaped as the reference's C<LoadedConfig>, Maps as arrays of
C<[name, source]> pairs in Map order – for comparing with the TypeScript side.

=head2 source_fields

  Skilletor::Config->source_fields( $def, 'file: sources.name', $needs_backend );

One source definition checked field by field, as the loader and C<add> check
it; returns the fields present. C<$needs_backend> defaults to true.

=head2 source_entry

  Skilletor::Config->source_entry( $file, $name );

=head2 add_source

  Skilletor::Config->add_source( $file, $name, $def );

A plain C<$def> is written in the reference's field order (C<git>, C<ref>,
C<url>, C<local>, C<path>); a L<Skilletor::JSON/js_ordered> one keeps its own.

=head2 remove_source

  Skilletor::Config->remove_source( $file, $name );

Drops the source; an emptied C<sources> goes too.

=head2 add_install_entry

  Skilletor::Config->add_install_entry( $file, $type, $entry );

=head2 find_install_entries

  Skilletor::Config->find_install_entries( $file, $name, $source, $type );

Entries matching a name (ignoring case; a pattern as written), optionally of
one source and one type: C<[ { type, entry } ]>.

=head2 remove_install_entries

Removes them; returns how many.

=head2 find_wildcard_entries

  Skilletor::Config->find_wildcard_entries( $file, $source, $type );

C<[ { type, entry, pattern } ]>.

=head2 bundle_entries

C<[ { name, source, entry } ]> of C<install.bundles>.

=head2 add_bundle_entry

  Skilletor::Config->add_bundle_entry( $file, 'perl@shared' );

Appends to C<install.bundles> unless that bundle of that source is listed.

=head2 remove_bundle_entries

  Skilletor::Config->remove_bundle_entries( $file, $name, $source );

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
