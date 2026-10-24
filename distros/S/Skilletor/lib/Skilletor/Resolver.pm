package Skilletor::Resolver;
# ABSTRACT: What each scope resolves to – a sync's steps 1–3, stopped before anything is built

use Moo;
use Carp qw( croak );
use Scalar::Util qw( blessed );
use Skilletor::Backend;
use Skilletor::Bundles qw( expand_bundle entry_miss match_entry matches_pattern same_identity );
use Skilletor::Cache qw( cache_name git_identity );
use Skilletor::Catalog;
use Skilletor::Config;
use Skilletor::Entry qw( WILDCARD name_key );
use Skilletor::FSUtil qw( path_join same_path );
use Skilletor::JSON qw( js_ordered js_stringify js_type );
use Skilletor::Lock qw( read_lock key_to_type_name );
use Skilletor::Source::Git;
use Skilletor::Source::Url;
use Skilletor::State;
use Skilletor::Targets qw( default_markers detect_harnesses select_targets );
use namespace::clean;

our $VERSION = '0.001';

my %TYPE_DIR = ( skill => 'skills', agent => 'agents', rule => 'rules' );
my %FETCH    = map { $_ => 1 } qw( always missing never );

has home => (
  is       => 'ro',
  required => 1,
);

has project_dir => (
  is => 'ro',
);

# `CLAUDE_CONFIG_DIR` (k145): Claude Code's config dir, which is the user scope's `.claude` –
# config, lock, state, roots – and where its plugin state lives. Empty means unset.
has claude_config_dir => (
  is      => 'lazy',
  builder => sub { $ENV{CLAUDE_CONFIG_DIR} },
);

has state_root => (
  is      => 'lazy',
  builder => sub { Skilletor::State->default_root( $_[0]->home, $_[0]->claude_config_dir ) },
);

has cache_root => (
  is      => 'lazy',
  builder => sub { path_join( $_[0]->state_root, 'cache' ) },
);

# `$CODEX_HOME`, for the harness markers; empty means unset.
has codex_home => (
  is      => 'lazy',
  builder => sub { $ENV{CODEX_HOME} },
);

has markers => (
  is      => 'lazy',
  builder => sub {
    my ( $self ) = @_;
    my $cx = $self->codex_home;
    my $cd = $self->claude_config_dir;
    return default_markers( $self->home, ( defined $cx && length $cx ) ? $cx : undef, ( defined $cd && length $cd ) ? $cd : undef );
  },
);

has require_harness => (
  is      => 'ro',
  default => sub { 0 },
);

has fetch => (
  is      => 'ro',
  default => sub { 'always' },
  isa     => sub { croak 'fetch must be always, missing or never' unless defined $_[0] && $FETCH{ $_[0] } },
);

has timeout_ms => (
  is => 'ro',
);

has lock_timeout_ms => (
  is      => 'ro',
  default => sub { 5_000 },
);

sub _message {
  my ( $err ) = @_;
  return $err->message if blessed $err && $err->can('message');
  return ( "$err" =~ s/ at \S+ line \d+\.?\n?\z//r );
}

# The project dir, unless it is the home dir itself: then there is no project scope (spec §6.1).
sub project_dir_of {
  my ( $self ) = @_;
  my $p = $self->project_dir;
  return undef if !defined $p || !length $p || same_path( $p, $self->home );
  return $p;
}

# Claude Code's config dir: the explicit one, else `<home>/.claude`.
sub claude_dir {
  my ( $self ) = @_;
  my $cd = $self->claude_config_dir;
  return ( defined $cd && length $cd ) ? $cd : path_join( $self->home, '.claude' );
}

# The scope's `.claude` directory: config, lock and the claude target root.
sub _target_dir {
  my ( $self, $scope ) = @_;
  return $scope eq 'user' ? $self->claude_dir : path_join( $self->_base_of($scope), '.claude' );
}

sub _base_of {
  my ( $self, $scope ) = @_;
  return $scope eq 'user' ? $self->home : $self->project_dir_of;
}

# Config and targets. A harness is only needed with require_harness (the reference's sync
# needs one); without it a machine with none resolves all the same, with no targets warnings.
sub _load {
  my ( $self ) = @_;
  my $config = Skilletor::Config->load( home => $self->home, claude_config_dir => $self->claude_config_dir, project_dir => $self->project_dir_of );
  my $markers = $self->markers;
  my $wanted = { user => $config->user->{targets}, project => $config->project ? $config->project->{targets} : undef };
  my $targets = eval { select_targets( $wanted, detect_harnesses($markers), $markers ) };
  unless ($targets) {
    die $@ if $self->require_harness;
    $targets = { user => [], project => [], warnings => [] };
  }
  return ( $config, $targets );
}

sub resolve {
  my ( $self, %opts ) = @_;
  my $sel = $opts{scope} // 'all';
  croak 'scope must be user, project or all' unless $sel =~ /\A(?:user|project|all)\z/;
  my $state = Skilletor::State->new( root => $self->state_root );
  return $state->with_lock(
    sub {
      Skilletor::Source::Url->sweep_cache( $self->cache_root );
      Skilletor::Source::Git->sweep_cache( $self->cache_root );
      my ( $config, $targets );
      unless ( eval { ( $config, $targets ) = $self->_load; 1 } ) {
        my $err = $@;
        die $err if $opts{throw};
        return { scopes => [], error => _message($err) };
      }
      my $run = {};    # each backend resolved once per run, for both scopes
      my @scopes;
      push @scopes, [ user => $config->user ] if $sel eq 'user' || $sel eq 'all';
      push @scopes, [ project => $config->project ] if ( $sel eq 'project' || $sel eq 'all' ) && $config->project;
      my $out = { scopes => [] };
      for my $s (@scopes) {
        my ( $scope, $scope_cfg ) = @$s;
        my $rep = $self->_resolve_scope( $config, $scope_cfg, $scope, $state, $run );
        unshift @{ $rep->{warnings} }, @{ $targets->{warnings} } if $scope eq 'project';
        push @{ $out->{scopes} }, $rep;
      }
      return $out;
    },
    timeout_ms => $self->lock_timeout_ms,
  );
}

# Every source a scope references, through explicit entries, wildcards or bundles.
sub _scope_sources {
  my ( $scope_cfg ) = @_;
  my ( %seen, @out );
  for my $i ( @{ $scope_cfg->{install} }, @{ $scope_cfg->{wildcards} }, @{ $scope_cfg->{bundles} } ) {
    push @out, $i->{source} unless $seen{ $i->{source} }++;
  }
  return @out;
}

sub bundle_label {
  my ( $class, $b ) = @_;
  return 'bundle:'.$b->{name}.'@'.$b->{source};
}

# The configured source serving a bundle entry of another source (spec §15.6): the first, in
# config order, whose `git`/`url` identity is $url.
sub _serving_source {
  my ( $config, $scope, $url ) = @_;
  for my $src ( @{ $config->sources_of($scope) } ) {
    my $id = $src->{git} // $src->{url};
    return $src->{name} if defined $id && same_identity( $id, $url );
  }
  return undef;
}

# A backend through the run's one resolve of it, under the fetch policy.
sub _resolve_backend {
  my ( $self, $run, $backend ) = @_;
  my $key = Skilletor::Backend->identity($backend);
  $run->{$key} //= do {
    my $loc;
    eval { $loc = $self->_fetch($backend); 1 } ? { ok => $loc } : { err => $@ };
  };
  die $run->{$key}{err} if exists $run->{$key}{err};
  return $run->{$key}{ok};
}

sub _fetch {
  my ( $self, $backend ) = @_;
  my $src = Skilletor::Backend->make( $backend, $self->cache_root, $self->timeout_ms );
  my $fetch = $self->fetch;
  return $src->resolve if $fetch eq 'always' || $backend->{kind} eq 'local';
  return $src->cached if $fetch eq 'never';
  my $loc = eval { $src->cached };
  return $loc if $loc && $loc->{version} ne 'unknown';
  return $src->resolve;
}

sub _item_vars {
  my ( @layers ) = @_;
  my $out = js_ordered();
  for my $l ( grep { defined } @layers ) {
    if ( ref $l eq 'ARRAY' ) { $out->{$_} = $l->[$_] for 0 .. $#$l }    # { ...array }: by index
    else                     { $out->{$_} = $l->{$_} for keys %$l }
  }
  return $out;
}

sub _uniq {
  my ( %seen, @out );
  for (@_) { push @out, $_ unless $seen{$_}++ }
  return @out;
}

sub _str_eq { defined $_[0] && defined $_[1] && !ref $_[0] && $_[0] eq $_[1] }

# `entry.via?.includes(label)`: the array holds exactly the label (read_lock refuses any other `via`).
sub _via_has {
  my ( $via, $label ) = @_;
  return 0 unless ref $via eq 'ARRAY';
  return ( grep { _str_eq( $_, $label ) } @$via ) ? 1 : 0;
}

sub _valid_item_name { $_[0] =~ /\A[A-Za-z0-9._\-]+\z/ ? 1 : 0 }

# Bundle vars of one item from every chain it was reached through (spec §15.3): a key every
# setting chain agrees on applies; one set to different values applies from none.
sub _merge_chain_vars {
  my ( $chains, $source, $conflict ) = @_;
  my ( %values, @order );
  for my $c (@$chains) {
    for my $key ( keys %{ $c->{vars} } ) {
      my $setter = __PACKAGE__->bundle_label( { name => $c->{setters}{$key}, source => $source } );
      push @order, $key unless $values{$key};
      push @{ $values{$key} }, { value => $c->{vars}{$key}, setter => $setter };
    }
  }
  my $out = js_ordered();
  for my $key (@order) {
    my $list = $values{$key};
    if ( _uniq( map { js_stringify( $_->{value} ) } @$list ) == 1 ) {
      $out->{$key} = $list->[0]{value};
    }
    else {
      $conflict->( $key, [ _uniq( map { $_->{setter} } @$list ) ] );
    }
  }
  return $out;
}

# One scope, as the reference's syncScopeRun runs it: without $hooks with `collect` (the items
# into the report), with them for a sync (Skilletor::Engine) – `declare` sees each declared item
# before its lookup (false: no target gets it, nothing is looked up), `build` each one found,
# `keep` the target and type of each one a sync must leave as it is installed. In list context
# also what the sync needs of the run: { resolved, resolved_order, catalogs, served, old_lock }.
sub _resolve_scope {
  my ( $self, $config, $scope_cfg, $scope, $state, $run, $hooks ) = @_;
  my $keep_if_locked = $hooks ? $hooks->{keep} : sub { };
  my $rep = { scope => $scope, warnings => [], trustRequests => [], items => [], sources => [] };
  my $warnings = $rep->{warnings};
  my $target_dir = $self->_target_dir($scope);
  my $old_lock = read_lock( path_join( $target_dir, 'skilletor.lock.json' ) );

  # Every needed source, trust checked and resolved against the one chosen backend.
  my ( %resolved, @resolved_order );
  my $set = sub {
    my ( $name, $value ) = @_;
    push @resolved_order, $name unless exists $resolved{$name};
    $resolved{$name} = $value;
  };
  my $resolve_all = sub {
    # The names not resolved yet, each once, decided up front, as the reference starts them all at once.
    my %once;
    for my $name ( grep { !exists $resolved{$_} && !$once{$_}++ } @_ ) {
      my $src = $config->source_of( $scope, $name );
      unless ($src) {
        push @$warnings, 'unknown source: '.$name;
        $set->( $name, undef );
        next;
      }
      my $ok = eval {
        my $backend = Skilletor::Backend->resolve( $src, $self->home );
        if ( !$state->is_trusted( $name, $backend ) ) {
          push @{ $rep->{trustRequests} }, Skilletor::Backend->trust_request( $name, $backend );
          $set->( $name, undef );
          return 1;
        }
        my $loc = $self->_resolve_backend( $run, $backend );
        # A shared resolve's warning (a fetch that fell back to the cache) is named once.
        push @$warnings, $loc->{warning} if defined $loc->{warning} && !grep { $_ eq $loc->{warning} } @$warnings;
        $set->( $name, { dir => $loc->{dir}, version => $loc->{version}, backend => $backend } );
        1;
      };
      next if $ok;
      push @$warnings, 'source '.$name.': '._message($@);
      $set->( $name, undef );
    }
  };
  $resolve_all->( _scope_sources($scope_cfg) );

  my %catalogs;
  my $catalog_of = sub {
    my ( $source ) = @_;
    return $catalogs{$source} if exists $catalogs{$source};
    my $r = $resolved{$source};
    my $cat;
    if ($r) {
      $cat = eval { Skilletor::Catalog->scan( $r->{dir}, $r->{backend}{path} ) };
      push @$warnings, 'source '.$source.': '._message($@) unless $cat;
    }
    return $catalogs{$source} = $cat;
  };

  my $lookup = sub {
    my ( $item ) = @_;
    my $r   = $resolved{ $item->{source} };
    my $cat = $catalog_of->( $item->{source} );
    unless ( $r && $cat ) {
      $keep_if_locked->( $item->{target}, $item->{type} );
      return undef;
    }
    my ($ci) = grep { $_->{type} eq $item->{type} && $_->{name} eq $item->{name} } @{ $cat->{items} };
    unless ($ci) {
      push @$warnings, 'item not found in source '.$item->{source}.': '.$item->{type}.' '.$item->{name};
      $keep_if_locked->( $item->{target}, $item->{type} );
      return undef;
    }
    if ( defined $ci->{error} ) {
      # An error of the item itself (spec §4.1): it is not built, what it installed stays.
      push @$warnings, $item->{type}.' '.$item->{name}.'@'.$item->{source}.': '.$ci->{error}.'; an installed copy stays';
      $keep_if_locked->( $item->{target}, $item->{type} );
      return undef;
    }
    return { r => $r, cat => $cat, item => $ci };
  };

  my $build_item = sub {
    my ( $item, $extra ) = @_;
    if ($hooks) {
      $hooks->{declare}->($item) or return;
      my $found = $lookup->($item) or return;
      $hooks->{build}->( $item, $extra // {}, $found, $warnings );
      return;
    }
    my $found = $lookup->($item) or return;
    my $ri = {
      type       => $item->{type},
      name       => $item->{name},
      source     => $item->{source},
      declaredBy => $extra->{declaredBy} // [],
      sourceDir  => $found->{r}{dir},
      item       => $found->{item},
      vars       => _item_vars( $found->{cat}{meta}{vars}, $extra->{bundleVars}, $scope_cfg->{vars} ),
    };
    $ri->{via} = $extra->{via} if $extra->{via} && @{ $extra->{via} };
    push @{ $rep->{items} }, $ri;
  };

  # Wildcards and bundles as offers per target, by name ignoring case (k135). An unresolvable
  # source (or a bundle that cannot be expanded) offers what it installed before.
  my ( %offers, @offer_order );
  my $target_key = sub { $TYPE_DIR{ $_[0] }.'/'.name_key( $_[1] ) };
  my $offer = sub {
    my ( $type, $name, $o ) = @_;
    my $key = $target_key->( $type, $name );
    unless ( $offers{$key} ) {
      $offers{$key} = { type => $type, offers => [] };
      push @offer_order, $key;
    }
    my $entry = $offers{$key};
    push @{ $entry->{offers} }, { %$o, name => $name } unless grep { $_->{from} eq $o->{from} && $_->{name} eq $name } @{ $entry->{offers} };
  };
  my @locked = map { +{ %{ key_to_type_name($_) }, entry => $old_lock->{$_} } } keys %$old_lock;
  my $entry_source = sub { my $e = $_[0]{entry}; return js_type($e) eq 'object' ? $e->{source} : undef };

  for my $w ( @{ $scope_cfg->{wildcards} } ) {
    if ( my $cat = $catalog_of->( $w->{source} ) ) {
      my @hits = grep { $_->{type} eq $w->{type} && matches_pattern( $w->{pattern}, $_->{name} ) } @{ $cat->{items} };
      # A bare `*` may legitimately match nothing (a source without rules): silent (spec §3).
      if ( !@hits && $w->{pattern} ne WILDCARD ) {
        push @$warnings, $w->{type}.' wildcard '.$w->{raw}.' matches nothing in source '.$w->{source};
      }
      $offer->( $w->{type}, $_->{name}, { from => $w->{raw}, source => $w->{source}, live => 1 } ) for @hits;
    }
    else {
      for my $l (@locked) {
        next unless _str_eq( $entry_source->($l), $w->{source} ) && $l->{type} eq $w->{type} && matches_pattern( $w->{pattern}, $l->{name} );
        $offer->( $l->{type}, $l->{name}, { from => $w->{raw}, source => $w->{source}, live => 0 } );
      }
    }
  }

  # Bundles: expanded against their own source first; entries of other sources (spec §15.6)
  # are served by a configured source with the same identity, resolved next.
  my @expansions = map {
    my $b     = $_;
    my $label = __PACKAGE__->bundle_label($b);
    my $cat   = $catalog_of->( $b->{source} );
    my $expanded;
    if ($cat) {
      unless ( eval { $expanded = expand_bundle( $cat, $b->{name} ); 1 } ) {
        my $err = $@;
        die $err unless blessed $err && $err->isa('Skilletor::Error::Bundle');
        push @$warnings, $label.': '.$err->message.'; its installed items are kept';
      }
    }
    my @foreign = map { +{ f => $_, served => _serving_source( $config, $scope, $_->{url} ) } } @{ $expanded ? $expanded->{foreign} : [] };
    +{ b => $b, label => $label, expanded => $expanded, foreign => \@foreign };
  } @{ $scope_cfg->{bundles} };
  $resolve_all->( map { map { defined $_->{served} ? $_->{served} : () } @{ $_->{foreign} } } @expansions );

  for my $x (@expansions) {
    my ( $b, $label, $expanded ) = @{$x}{qw( b label expanded )};
    my $keep_from_lock = sub {
      my ( $match ) = @_;
      for my $l (@locked) {
        next unless js_type( $l->{entry} ) eq 'object' && _via_has( $l->{entry}{via}, $label ) && $match->($l);
        $offer->( $l->{type}, $l->{name}, { from => $label, source => $l->{entry}{source}, live => 0, via => $label } );
      }
    };
    unless ($expanded) {
      $keep_from_lock->( sub { 1 } );
      next;
    }
    push @$warnings, 'bundle '.$_->{bundle}.'@'.$b->{source}.': '.$_->{message} for @{ $expanded->{warnings} };
    for my $m ( @{ $expanded->{items} } ) {
      $offer->( $m->{type}, $m->{name}, { from => $label, source => $b->{source}, live => 1, via => $label, chains => $m->{chains} } );
    }
    my @missing;    # identities already warned about for this bundle
    for my $fs ( @{ $x->{foreign} } ) {
      my ( $f, $served ) = @{$fs}{qw( f served )};
      my $cat = defined $served ? $catalog_of->($served) : undef;
      if ( !defined $served && !grep { same_identity( $_, $f->{url} ) } @missing ) {
        push @missing, $f->{url};
        push @$warnings, 'bundle '.$b->{name}.'@'.$b->{source}.' needs '.$f->{spec}.' ('.$f->{url}.'): run skilletor install '.$label;
      }
      unless ($cat) {
        # Missing, untrusted or unresolvable: installed copies stay (spec §15.6).
        $keep_from_lock->(
          sub {
            my ( $l ) = @_;
            my $ls = $l->{entry}{source};
            return $l->{type} eq $f->{type} && !_str_eq( $ls, $b->{source} ) && matches_pattern( $f->{name}, $l->{name} )
              && ( !defined $served || _str_eq( $ls, $served ) );
          }
        );
        next;
      }
      my $hits = match_entry( $cat, $f->{type}, $f->{name} );
      if ( defined( my $miss = entry_miss( $f->{type}, $f->{name}, scalar @$hits ) ) ) {
        push @$warnings, 'bundle '.$f->{chain}{path}[-1].'@'.$b->{source}.': '.( $miss =~ s/ in the source\z//r ).' in '.$served;
      }
      for my $ci (@$hits) {
        $offer->( $ci->{type}, $ci->{name}, { from => $label, source => $served, live => 1, via => $label, chains => [ $f->{chain} ] } );
      }
    }
  }

  # Explicit entries win over every offer; they get no bundle vars (spec §15.3), but record the
  # same-source bundles that also yield them.
  my %explicit;
  for my $item ( @{ $scope_cfg->{install} } ) {
    my $key = $target_key->( $item->{type}, $item->{name} );
    $explicit{$key} = { source => $item->{source}, raw => $item->{raw} };
    my @via = map { $_->{via} } grep { defined $_->{via} && _str_eq( $_->{source}, $item->{source} ) && $_->{name} eq $item->{name} }
      @{ $offers{$key} ? $offers{$key}{offers} : [] };
    $build_item->( $item, { via => \@via, declaredBy => [ $item->{raw} ] } );
  }

  # Bundle var conflicts (spec §15.3), reported once per key and pair of bundles.
  my ( %conflicts, @conflict_order );
  for my $key (@offer_order) {
    my $o = $offers{$key};
    if ( my $claim = $explicit{$key} ) {
      for my $x ( @{ $o->{offers} } ) {
        next if _str_eq( $x->{source}, $claim->{source} );
        push @$warnings, $o->{type}.' "'.$x->{name}.'" from '.$x->{from}.' ignored: explicitly declared as '.$claim->{raw};
      }
      next;
    }
    my @names = _uniq( map { $_->{name} } @{ $o->{offers} } );
    if ( _uniq( map { $_->{source} // '' } @{ $o->{offers} } ) > 1 ) {
      my @from = _uniq( map { $_->{from} } @{ $o->{offers} } );
      push @$warnings, $o->{type}.' '.join( ' and ', map { '"'.$_.'"' } @names ).' offered by '.join( ' and ', @from ).'; skipped';
      $keep_if_locked->( $TYPE_DIR{ $o->{type} }.'/'.$_, $o->{type} ) for @names;
      next;
    }
    # One source: installed once, however many of its wildcards and bundles yield it.
    my $source = $o->{offers}[0]{source};
    for my $name (@names) {
      my @mine = grep { $_->{name} eq $name } @{ $o->{offers} };
      my @live = grep { $_->{live} } @mine;
      unless (@live) {
        $keep_if_locked->( $TYPE_DIR{ $o->{type} }.'/'.$name, $o->{type} );
        next;
      }
      unless ( _valid_item_name($name) ) {
        push @$warnings, $o->{type}.' "'.$name.'" from '.$live[0]{from}.' skipped: invalid item name';
        next;
      }
      my @via    = map { defined $_->{via} ? $_->{via} : () } @mine;
      my @chains = map { @{ $_->{chains} // [] } } @live;
      my $bundle_vars = _merge_chain_vars(
        \@chains, $source,
        sub {
          my ( $var, $setters ) = @_;
          my $k = '"'.$var.'": '.join( ' and ', @$setters );
          push @conflict_order, $k unless $conflicts{$k};
          push @{ $conflicts{$k} }, $o->{type}.' '.$name;
        }
      );
      $build_item->(
        { type => $o->{type}, name => $name, source => $source, target => $TYPE_DIR{ $o->{type} }.'/'.$name },
        { bundleVars => $bundle_vars, via => \@via, declaredBy => [ _uniq( map { $_->{from} } @live ) ] },
      );
    }
  }
  for my $k (@conflict_order) {
    push @$warnings, 'bundle vars conflict on '.$k.' set different values; neither applies to '.join( ', ', @{ $conflicts{$k} } );
  }

  if ($hooks) {
    my $run_info = {
      resolved       => \%resolved,
      resolved_order => \@resolved_order,
      catalogs       => \%catalogs,
      old_lock       => $old_lock,
      # Per bundle label, the other sources its entries are served by (spec §15.6).
      served => { map { ( $_->{label} => [ map { defined $_->{served} ? $_->{served} : () } @{ $_->{foreign} } ] ) } @expansions },
    };
    undef $_ for $resolve_all, $catalog_of, $lookup, $build_item, $offer, $set;
    return wantarray ? ( $rep, $run_info ) : $rep;
  }

  # The sources the scope needed, and what became of them.
  for my $name (@resolved_order) {
    my $r   = $resolved{$name};
    my $src = $config->source_of( $scope, $name );
    my $backend = $r ? $r->{backend} : undef;
    $backend = eval { Skilletor::Backend->resolve( $src, $self->home ) } if !$backend && $src;
    my $info = { name => $name, state => 'failed' };
    if    ( !$src ) { $info->{state} = 'unknown' }
    elsif ( $r && !( exists $catalogs{$name} && !defined $catalogs{$name} ) ) { $info->{state} = 'resolved' }
    elsif ( !$r && grep { $_->{name} eq $name } @{ $rep->{trustRequests} } ) { $info->{state} = 'untrusted' }
    if ($backend) {
      $info->{backend} = $backend;
      $info->{cache} = cache_name( git_identity( $backend->{address}, $backend->{ref} ) ) if $backend->{kind} eq 'git';
      $info->{cache} = cache_name( $backend->{address} ) if $backend->{kind} eq 'url';
    }
    if ($r) {
      $info->{dir}     = $r->{dir};
      $info->{version} = $r->{version};
    }
    push @{ $rep->{sources} }, $info;
  }
  # The closures above refer to each other through these; break the cycles.
  undef $_ for $resolve_all, $catalog_of, $lookup, $build_item, $offer, $set;
  return $rep;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Skilletor::Resolver - What each scope resolves to – a sync's steps 1–3, stopped before anything is built

=head1 VERSION

version 0.001

=head1 SYNOPSIS

  use Skilletor::Resolver;

  my $r = Skilletor::Resolver->new( home => $ENV{HOME}, project_dir => $cwd );
  my $report = $r->resolve( scope => 'all' );
  # { scopes => [ { scope => 'user', items => [...], sources => [...], warnings => [...], trustRequests => [...] }, ... ] }
  # or { scopes => [], error => '…/skilletor.json: …' }

=head1 DESCRIPTION

The port of the reference's C<resolveItems> (C<engine.ts>, k143): a sync's own
steps 1–3 (spec §6.1) – config load and merge, trust, every needed source
resolved into the shared cache, catalogs scanned, wildcards and bundles
expanded with the overlap rules (spec §3, §15) – stopped before anything is
built: nothing is rendered, nothing written to a target, the lock or the
state's records. Like the reference it holds the sync lock
(L<Skilletor::State/with_lock>) while it runs and sweeps what a killed run left
in the cache first. Most callers want the item lookups of L<Skilletor>.
L<Skilletor::Engine> extends this class: a sync runs the very same scope
resolution, as the reference's C<syncScopeRun> serves both, and builds what it
finds.

The report is the reference's C<ResolveReport>, field for field, so the two
compare directly (the shared conformance cases do): per scope its C<items>,
C<sources>, C<warnings> – the same texts – and C<trustRequests>.

An item:

  {
    type => 'skill', name => 'perl-moo', source => 'shared',
    declaredBy => [ 'perl-moo@shared' ],          # the entries declaring it, as written
    via        => [ 'bundle:perl@shared' ],       # only when bundles yield it too
    sourceDir  => '/home/me/.claude/skilletor/cache/79eb247685294166',
    item       => { type, name, dir?, files => [ relative paths ], description?, error? },
    vars       => { ... },                        # source < bundle < user < project < local
  }

A source: C<< { name, state => 'resolved' | 'untrusted' | 'failed' | 'unknown',
backend?, cache?, dir?, version? } >>.

Two differences from the reference are deliberate and switchable:

=over 4

=item * B<No harness needed.> The reference fails a resolve, like a sync, with
"no agent harness detected" on a machine with neither Claude Code nor Codex
markers, although resolution does not depend on a harness. Here that check is
only made with L</require_harness>; without it the targets warnings (project
targets not in use here) are given when a harness is known and left out
otherwise.

=item * B<Fetch policy.> L</fetch> C<always> (the default) resolves every
source as a sync does: git fetches, url downloads, a failure falls back to the
cache with a warning. C<missing> fetches only a source with no usable cache
yet, C<never> fetches nothing and serves what the cache holds (a source never
fetched is a warning). Both read the cache the reference writes.

=back

=head2 home

Required.

=head2 project_dir

The project; none, or the home dir itself, means no project scope.

=head2 claude_config_dir

C<CLAUDE_CONFIG_DIR> by default; an empty value counts as unset, then F<< <home>/.claude >>.
Claude Code's config dir is the user scope's C<.claude>: the user config, the lock, the
Claude roots, the state dir, Claude's own marker (C<.claude.json>) and plugin state, and
the briefing lookup's skills all lie under it.

=head2 state_root

Default C<< <claude_config_dir>/skilletor >>, so F<< <home>/.claude/skilletor >> (trust, the sync lock).

=head2 cache_root

Default C<< <state_root>/cache >>.

=head2 codex_home

C<$CODEX_HOME> by default: where Codex's markers lie.

=head2 markers

The harness markers (L<Skilletor::Targets/default_markers>).

=head2 require_harness

True: fail as the reference does when no harness is detected and the user
config names no C<targets>. Default false.

=head2 fetch

C<always> (default), C<missing> or C<never>.

=head2 timeout_ms

Per-source network timeout; the backends' default without it.

=head2 lock_timeout_ms

How long to wait for another holder of the sync lock (default 5000).

=head2 resolve

  $r->resolve( scope => 'user' | 'project' | 'all', throw => 0 );

The report. A config error (or, with L</require_harness>, a missing harness)
is its C<error>, with no scopes – or thrown with C<throw>. An unreadable lock
file and a sync lock held too long throw.

=head2 project_dir_of

The project dir in effect (undef when there is no project scope).

=head2 bundle_label

  Skilletor::Resolver->bundle_label( { name => 'perl', source => 'shared' } );   # bundle:perl@shared

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
