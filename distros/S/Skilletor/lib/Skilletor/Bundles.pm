package Skilletor::Bundles;
# ABSTRACT: Bundle files (spec §15), their expansion, and name patterns

use strict;
use warnings;

use Exporter qw( import );
use Scalar::Util qw( blessed );
use Skilletor::Config;
use Skilletor::Error::Bundle;
use Skilletor::Error::Spec;
use Skilletor::Frontmatter qw( parse_yaml_document is_yaml_float );
use Skilletor::JSON qw( js_ordered js_stringify js_type );
use Skilletor::JSString qw( js_lc js_trim );
use Skilletor::Spec qw( resolve_spec );

our $VERSION = '0.001';

our @EXPORT_OK = qw(
  PATTERN_CHAR is_pattern matches_pattern same_identity match_entry
  parse_bundle expand_bundle entry_miss
);

# The character that makes a name a pattern (spec §3).
use constant PATTERN_CHAR => '*';

my $DOT = qr/[^\n\r\x{2028}\x{2029}]/;    # JavaScript's `.`

my @TYPE_KEYS = ( skills => 'skill', agents => 'agent', rules => 'rule' );
my @KEYS      = qw( description skills agents rules bundles vars );
my %KEY       = map { $_ => 1 } @KEYS;

sub is_pattern {
  my ( $name ) = @_;
  return index( $name, PATTERN_CHAR ) >= 0 ? 1 : 0;
}

# `*` matches any run of characters but a line terminator (JavaScript's `.*`); the rest is literal.
sub matches_pattern {
  my ( $pattern, $name ) = @_;
  my $re = join "$DOT*", map { quotemeta } split /\Q${\PATTERN_CHAR}\E/, $pattern, -1;
  return $name =~ /\A$re\z/ ? 1 : 0;
}

# Two source identities (`git`/`url` values) are the same modulo a trailing `/`, `.git` and host case.
sub same_identity {
  my ( $a, $b ) = @_;
  return _normalize_identity($a) eq _normalize_identity($b) ? 1 : 0;
}

sub _normalize_identity {
  my ( $u ) = @_;
  ( my $s = js_trim($u) ) =~ s{/+\z}{};
  $s =~ s/\.git\z//;
  if ( $s =~ m{\A([a-z][a-z0-9+.\-]*://)([^/]*)($DOT*)\z}i ) {
    $s = js_lc($1).js_lc($2).$3;
  }
  return $s;
}

# Catalog items of $type a name or pattern names (spec §3).
sub match_entry {
  my ( $cat, $type, $entry ) = @_;
  return [ grep { $_->{type} eq $type && matches_pattern( $entry, $_->{name} ) } @{ $cat->{items} } ] if is_pattern($entry);
  return [ grep { $_->{type} eq $type && $_->{name} eq $entry } @{ $cat->{items} } ];
}

# The warning for an entry that matched $count items, if any (a bare `*` stays silent, spec §3).
sub entry_miss {
  my ( $type, $entry, $count ) = @_;
  return undef if $count > 0 || $entry eq PATTERN_CHAR;
  return is_pattern($entry) ? 'pattern '.$type.':'.$entry.' matches nothing' : $type.' '.$entry.' not found in the source';
}

sub _fail { Skilletor::Error::Bundle->throw( $_[0] ) }

sub _message { my ( $err ) = @_; return blessed $err && $err->can('message') ? $err->message : "$err" =~ s/ at \S+ line \d+\.?\n?\z//r }

# A YAML value as plain JSON-like data (floats become numbers).
sub _plain {
  my ( $v ) = @_;
  return $v->value if is_yaml_float($v);
  return [ map { _plain($_) } @$v ] if ref $v eq 'ARRAY';
  return js_ordered( map { ( $_ => _plain( $v->{$_} ) ) } keys %$v ) if ref $v eq 'HASH';
  return $v;
}

sub _string_list {
  my ( $value, $key ) = @_;
  return [] unless defined $value;
  _fail( $key.' must be a list' ) unless ref $value eq 'ARRAY';
  return [
    map {
      _fail( $key.' entries must be strings (got '.js_stringify( _plain($_) ).')' ) unless _is_string($_);
      _fail( $key.' has an empty entry' ) if js_trim($_) eq '';
      js_trim($_);
    } @$value
  ];
}

sub _is_string { my ( $v ) = @_; return !ref $v && js_type($v) eq 'string' }

# `name@<spec>` resolved without a probe (spec §15.6): local paths, generic hosts, an address
# config load would refuse as a source and a ref or a path pinned by the address are errors.
sub _foreign_entry {
  my ( $type, $entry, $key ) = @_;
  my $at   = index $entry, '@';
  my $name = substr $entry, 0, $at;
  my $spec = substr $entry, $at + 1;
  _fail( $key.': "'.$entry.'" has an empty name or address' ) if $name eq '' || $spec eq '';
  my $r;
  my $ok = eval {
    $r = resolve_spec( $spec, sub { Skilletor::Error::Spec->throw('probe') } );
    if ( $r->{kind} eq 'local' ) {
      _fail( $key.': "'.$entry.'" names a local path; a bundle can only name remote sources' );
    }
    if ( defined $r->{ref} ) {
      my $pins = 'ref '.js_stringify( $r->{ref} ).( defined $r->{path} ? ' and path '.js_stringify( $r->{path} ) : '' );
      _fail( $key.': "'.$entry.'" pins '.$pins.', but an entry names its source by address alone: write '.$name.'@'.$r->{value} );
    }
    1;
  };
  unless ($ok) {
    my $err = $@;
    die $err if blessed $err && $err->isa('Skilletor::Error::Bundle');
    if ( blessed $err && $err->isa('Skilletor::Error::Spec') && $err->message eq 'probe' ) {
      _fail( $key.': "'.$entry.'": a generic host must be written as a full https:// URL' );
    }
    _fail( $key.': "'.$entry.'": '._message($err) );
  }
  my $field = $r->{kind} eq 'git' ? { git => $r->{value} } : { url => $r->{value} };
  unless ( eval { Skilletor::Config->source_fields( $field, 'sources.'.$r->{derivedName} ); 1 } ) {
    my $err = $@;
    die $err unless blessed $err && $err->isa('Skilletor::Error::Config');
    _fail( $key.': "'.$entry.'" cannot be added as a source: '.$err->message );
  }
  return {
    type        => $type,
    entry       => $entry,
    name        => $name,
    spec        => $spec,
    url         => $r->{value},
    kind        => $r->{kind},
    derivedName => $r->{derivedName},
  };
}

sub parse_bundle {
  my ( $text ) = @_;
  my $data;
  unless ( eval { $data = parse_yaml_document($text); 1 } ) {
    my $err = $@;
    _fail( $err->message ) if blessed $err && $err->isa('Skilletor::Error::Frontmatter');
    die $err;
  }
  for my $key ( keys %$data ) {
    _fail( 'unknown key "'.$key.'" (allowed: '.join( ', ', @KEYS ).')' ) unless $KEY{$key};
  }
  my $description = $data->{description};
  _fail('description is required (a string)') unless defined $description && _is_string($description) && js_trim($description) ne '';
  my %def = ( description => $description, items => [], foreign => [], bundles => [], vars => js_ordered() );
  my @pairs = @TYPE_KEYS;
  while ( my ( $key, $type ) = splice @pairs, 0, 2 ) {
    for my $entry ( @{ _string_list( $data->{$key}, $key ) } ) {
      if ( index( $entry, '@' ) >= 0 ) { push @{ $def{foreign} }, _foreign_entry( $type, $entry, $key ) }
      else                             { push @{ $def{items} }, { type => $type, entry => $entry } }
    }
  }
  for my $name ( @{ _string_list( $data->{bundles}, 'bundles' ) } ) {
    _fail( 'bundles: "'.$name.'" must be a bare name of this source' ) if index( $name, '@' ) >= 0;
    _fail( 'bundles: "'.$name.'": patterns over bundle names are not supported' ) if is_pattern($name);
    push @{ $def{bundles} }, $name;
  }
  my $vars = $data->{vars};
  if ( defined $vars ) {
    _fail('vars must be a mapping') unless ref $vars eq 'HASH' && !blessed $vars;
    $def{vars} = _plain($vars);
  }
  return \%def;
}

#### Expansion (spec §15.2) ############################################

sub _label_path { join '/', @{ $_[0] } }

sub expand_bundle {
  my ( $cat, $name ) = @_;
  my %by_name = map { ( $_->{name} => $_ ) } @{ $cat->{bundles} };
  my ( %members, @order );
  my $out = { items => [], foreign => [], warnings => [] };

  my $visit;
  $visit = sub {
    my ( $bundle, $path, $outer ) = @_;
    my $cb = $by_name{$bundle};
    my $where = @$path ? 'bundle '.$bundle.' (included by '.$path->[-1].')' : 'bundle '.$bundle;
    _fail( $where.' not found' ) unless $cb;
    _fail( $where.': '.$cb->{error} ) if defined $cb->{error};
    my $here = [ @$path, $bundle ];
    my $def  = $cb->{def};
    # Inner vars first, then the outer chain on top: the outer bundle wins.
    my $chain = { path => $here, vars => js_ordered( map { ( $_ => $def->{vars}{$_} ) } keys %{ $def->{vars} } ), setters => {} };
    $chain->{setters}{$_} = $bundle for keys %{ $def->{vars} };
    if ($outer) {
      $chain->{vars}{$_}    = $outer->{vars}{$_}    for keys %{ $outer->{vars} };
      $chain->{setters}{$_} = $outer->{setters}{$_} for keys %{ $outer->{setters} };
    }
    for my $it ( @{ $def->{items} } ) {
      my $found = match_entry( $cat, $it->{type}, $it->{entry} );
      my $miss  = entry_miss( $it->{type}, $it->{entry}, scalar @$found );
      push @{ $out->{warnings} }, { bundle => $bundle, message => $miss } if defined $miss;
      for my $ci (@$found) {
        my $key = $ci->{type}.'/'.$ci->{name};
        unless ( $members{$key} ) {
          $members{$key} = { type => $ci->{type}, name => $ci->{name}, chains => [] };
          push @order, $key;
        }
        my $m = $members{$key};
        push @{ $m->{chains} }, $chain unless grep { _label_path( $_->{path} ) eq _label_path($here) } @{ $m->{chains} };
      }
    }
    push @{ $out->{foreign} }, { %$_, chain => $chain } for @{ $def->{foreign} };
    for my $inner ( @{ $def->{bundles} } ) {
      my ($at) = grep { $here->[$_] eq $inner } 0 .. $#$here;
      _fail( 'bundle cycle '.join( " \x{2192} ", @{$here}[ $at .. $#$here ], $inner ) ) if defined $at;
      $visit->( $inner, $here, { %$chain, path => $here } );
    }
  };
  my $ok = eval { $visit->( $name, [], undef ); 1 };
  my $err = $@;
  undef $visit;    # the closure refers to itself
  die $err unless $ok;
  $out->{items} = [ map { $members{$_} } @order ];
  return $out;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Skilletor::Bundles - Bundle files (spec §15), their expansion, and name patterns

=head1 VERSION

version 0.001

=head1 SYNOPSIS

  use Skilletor::Bundles qw( parse_bundle expand_bundle matches_pattern );

  my $def = parse_bundle($yaml);
  # { description, items => [ { type, entry } ], foreign => [...], bundles => [...], vars => {...} }

  my $x = expand_bundle( $catalog, 'perl' );
  # { items => [ { type, name, chains => [ { path, vars, setters } ] } ], foreign => [...], warnings => [...] }

  matches_pattern( 'perl-*', 'perl-moo' );   # 1

=head1 DESCRIPTION

The reference's C<bundles.ts>. A bundle is C<< bundles/<name>.yaml|.yml >> in a
source: a named set of that source's items (names or C<*> patterns per type),
other bundles of the source included recursively, entries of other sources by
address (spec §15.6), and var defaults for the items it yields. Every error is
a L<Skilletor::Error::Bundle> worded as the reference words it; the YAML is
read by L<Skilletor::Frontmatter>.

=head2 parse_bundle

Parse and validate one bundle file (spec §15.1).

=head2 expand_bundle

  expand_bundle( $catalog, $name );

Expand a bundle of a L<Skilletor::Catalog> scan (spec §15.2): each item with
every chain of bundles it is reached through and that chain's vars (the outer
bundle winning, spec §15.3), the entries of other sources with their chain,
and a warning per entry that names nothing. A missing or broken bundle and a
cycle throw.

=head2 match_entry

  match_entry( $catalog, $type, $name_or_pattern );   # [ items ]

=head2 entry_miss

  entry_miss( $type, $entry, $count );   # the warning, or undef

=head2 matches_pattern

C<*> matches any run of characters; everything else is literal.

=head2 is_pattern

=head2 same_identity

Two C<git>/C<url> identities are the same modulo a trailing C</>, C<.git> and
the case of scheme and host.

=head2 PATTERN_CHAR

C<*>.

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
