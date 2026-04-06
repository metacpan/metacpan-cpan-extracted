package Modern::OpenAPI::Generator::CodeGen::StubData;

use v5.26;
use strict;
use warnings;
use Carp qw(croak);

# Generated ${base}::StubData — random JSON-shaped data from OpenAPI response
# schemas, then ${base}::Model::*->from_json when a generated model exists.

sub generate {
    my ( $class, %arg ) = @_;
    my $writer = $arg{writer} // croak 'writer';
    my $base   = $arg{base}   // croak 'base';

    my $lib = 'lib/' . _pathify_dir($base);
    my $pkg = "$base\::StubData";
    $writer->write( "$lib/StubData.pm", _stubdata_pm( $pkg, $base ) );
}

sub _pathify_dir {
    my ($name) = @_;
    $name =~ s{::}{/}g;
    return $name;
}

sub _stubdata_pm {
    my ( $pkg, $base ) = @_;

    # All $ below are escaped for the generated module; ${base} is interpolated once.
    return <<"PM";
package $pkg;

use v5.26;
use strict;
use warnings;

use Carp qw(croak);
use JSON::PP ();

our \$BASE = '$base';

sub for_operation {
  my ( \$class, \$operation_id ) = \@_;
  my \$raw = _load_spec();
  my \$op = _find_operation( \$raw, \$operation_id )
    // croak "operationId not in spec: \$operation_id";
  my ( \$status, \$sch ) = _first_json_response_schema( \$op->{responses} // {} );
  croak "no application/json response for \$operation_id" unless \$sch;
  my \$hash = _random_for_schema( \$raw, \$sch );
  my \$is_array = _top_level_array( \$sch );
  my \$mpkg     = _model_pkg_for_response( \$raw, \$sch );
  if ( length \$mpkg ) {
    my \$ok = eval "require \$mpkg; 1";
    if ( \$ok && \$mpkg->can('from_json') ) {
      my \$obj = \$mpkg->from_json( \$hash, \$is_array ? 1 : 0 );
      return ( \$status, \$obj );
    }
  }
  return ( \$status, \$hash );
}

sub _load_spec {
  state \$data;
  return \$data if \$data;
  my \$home = \$ENV{MOJO_HOME} // croak 'MOJO_HOME must be set when using StubData';
  my \$path = "\$home/share/openapi.yaml";
  croak "OpenAPI spec not found: \$path" unless -f \$path;
  require YAML::PP;
  \$data = YAML::PP->new( boolean => 'JSON::PP' )->load_file(\$path);
  return \$data;
}

sub _find_operation {
  my ( \$raw, \$want ) = \@_;
  my \$paths = \$raw->{paths} // {};
  for my \$p ( keys %\$paths ) {
    my \$item = \$paths->{\$p};
    next unless ref \$item eq 'HASH';
    for my \$m (qw(get put post delete patch options head trace)) {
      my \$op = \$item->{\$m};
      next unless ref \$op eq 'HASH';
      my \$oid = \$op->{operationId} // next;
      return \$op if \$oid eq \$want;
    }
  }
  return undef;
}

sub _first_json_response_schema {
  my (\$responses) = \@_;
  for my \$code (qw(200 201 202)) {
    next unless exists \$responses->{\$code};
    my \$content = \$responses->{\$code}{content} // {};
    for my \$ct (qw(application/json application/problem+json)) {
      next unless exists \$content->{\$ct};
      my \$sch = \$content->{\$ct}{schema};
      next unless ref \$sch eq 'HASH';
      return ( 0 + \$code, \$sch );
    }
  }
  return;
}

sub _top_level_array {
  my (\$sch) = \@_;
  return 0 unless ref \$sch eq 'HASH';
  return 1 if ( \$sch->{type} // '' ) eq 'array';
  return 0;
}

sub _model_pkg_for_response {
  my ( \$raw, \$sch ) = \@_;
  return '' unless ref \$sch eq 'HASH';
  if ( my \$r = \$sch->{'\$ref'} ) {
    return _model_pkg_for_schema_name( \$raw, \$r );
  }
  if ( ( \$sch->{type} // '' ) eq 'array' && ref \$sch->{items} eq 'HASH' ) {
    return _model_pkg_for_schema_name( \$raw, \$sch->{items}{'\$ref'} // '' );
  }
  return '';
}

sub _model_pkg_for_schema_name {
  my ( \$raw, \$ref ) = \@_;
  return '' unless defined \$ref && \$ref =~ m{#/components/schemas/([^/]+)\\z};
  my \$name = \$1;
  my \$def  = \$raw->{components}{schemas}{\$name};
  return '' unless ref \$def eq 'HASH';
  return '' if \$def->{allOf} || \$def->{oneOf} || \$def->{anyOf};
  return '' unless ( \$def->{type} // '' ) eq 'object' && ref \$def->{properties} eq 'HASH';
  ( my \$safe = \$name ) =~ s/[^A-Za-z0-9_]/_/g;
  return \$BASE . '::Model::' . \$safe;
}

sub _random_for_schema {
  my ( \$raw, \$sch ) = \@_;
  return {} unless ref \$sch eq 'HASH';
  if ( ref \$sch->{allOf} eq 'ARRAY' && \@{\$sch->{allOf}} ) {
    return _random_for_schema( \$raw, \$sch->{allOf}[0] );
  }
  if ( my \$ref = \$sch->{'\$ref'} ) {
    my \$res = _resolve_ref( \$raw, \$ref );
    return _random_for_schema( \$raw, \$res ) if ref \$res eq 'HASH';
  }
  my \$t = \$sch->{type} // '';
  if ( \$t eq 'array' || ( !length \$t && ref \$sch->{items} eq 'HASH' ) ) {
    my \$it = \$sch->{items} // {};
    return [] unless ref \$it eq 'HASH';
    return [ _random_for_schema( \$raw, \$it ) ];
  }
  if ( \$t eq 'object' || ( !length \$t && ref \$sch->{properties} eq 'HASH' ) ) {
    my \$props = \$sch->{properties} // {};
    my %out;
    for my \$k ( keys %\$props ) {
      \$out{\$k} = _random_for_schema( \$raw, \$props->{\$k} );
    }
    return \\%out;
  }
  if ( \$t eq 'string' ) {
    if ( ref \$sch->{enum} eq 'ARRAY' && \@{\$sch->{enum}} ) {
      return \$sch->{enum}[ int( rand( scalar \@{\$sch->{enum}} ) ) ];
    }
    return _rnd_str();
  }
  if ( \$t eq 'integer' ) {
    return int( rand( 2_000_000 ) ) - 1_000_000;
  }
  if ( \$t eq 'number' ) {
    return rand( 1_000_000 ) / 1000;
  }
  if ( \$t eq 'boolean' ) {
    return rand() < 0.5 ? JSON::PP::false : JSON::PP::true;
  }
  return {};
}

sub _resolve_ref {
  my ( \$raw, \$ref ) = \@_;
  return undef unless defined \$ref && \$ref =~ m{#/components/schemas/([^/]+)\\z};
  return \$raw->{components}{schemas}{\$1};
}

sub _rnd_str {
  join '', map { ( 'a' .. 'z', 'A' .. 'Z', 0 .. 9 )[ int( rand 62 ) ] } 1 .. ( 6 + int( rand 10 ) );
}

1;
PM
}

1;

__END__

=encoding utf8

=head1 NAME

Modern::OpenAPI::Generator::CodeGen::StubData - Generate C<::StubData> for local testing

=head1 DESCRIPTION

Emitted with C<--server --local-test> so controllers can return random
JSON-shaped data matching response schemas.

=head2 generate

Class method. Arguments: C<writer>, C<base>.

=cut
