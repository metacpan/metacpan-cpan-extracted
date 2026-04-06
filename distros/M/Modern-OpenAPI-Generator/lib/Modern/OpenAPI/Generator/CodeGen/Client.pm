package Modern::OpenAPI::Generator::CodeGen::Client;

use v5.26;
use strict;
use warnings;
use Carp qw(croak);
use Data::Dumper ();

sub generate {
    my ( $class, %arg ) = @_;
    my $writer   = $arg{writer}   // croak 'writer';
    my $spec     = $arg{spec}     // croak 'spec';
    my $base     = $arg{base}     // croak 'base';
    my $sync     = $arg{sync}     // 1;
    my $async    = $arg{async}    // 1;
    my $sigs     = $arg{signatures} // [];

    my $ops = $spec->operations;
    my $lib = 'lib/' . _pathify_dir($base);

    my $core_pkg    = "$base\::Client::Core";
    my $ops_pkg     = "$base\::Client::Ops";
    my $sync_pkg    = "$base\::Client::Sync";
    my $async_pkg   = "$base\::Client::Async";

    $writer->write( "$lib/Client/Core.pm", _core_pm( $core_pkg, $base, $sigs ) );
    $writer->write( "$lib/Client/Ops.pm",
        _ops_pm( $ops_pkg, $core_pkg, $ops, $sync, $async, $spec, $base ) );
    $writer->write( "$lib/Client/Sync.pm", _sync_pm( $sync_pkg, $ops_pkg, $core_pkg ) ) if $sync;
    $writer->write( "$lib/Client/Async.pm", _async_pm( $async_pkg, $ops_pkg, $core_pkg ) ) if $async;
}

sub _pathify_dir {
    my ($name) = @_;
    $name =~ s{::}{/}g;
    return $name;
}

sub _sanitize_sub {
    my ($s) = @_;
    $s =~ s{([a-z])([A-Z])}{$1_$2}g;
    $s =~ s{[^A-Za-z0-9]+}{_}g;
    return lc $s;
}

sub _response_model_pkg {
    my ( $spec, $base, $op ) = @_;
    my $ref = $op->{response_schema_ref} or return '';
    my ($name) = $ref =~ m{\#/components/schemas/([^/]+)\z} or return '';
    my $sch = $spec->raw->{components}{schemas}{$name};
    return '' unless ref $sch eq 'HASH';
    return '' if $sch->{allOf} || $sch->{oneOf} || $sch->{anyOf};
    return '' unless ( $sch->{type} // '' ) eq 'object' && ref $sch->{properties} eq 'HASH';
    ( my $safe = $name ) =~ s/[^A-Za-z0-9_]/_/g;
    return "$base\::Model::$safe";
}

sub _meta_literal {
    my ( $spec, $base, $op ) = @_;
    local $Data::Dumper::Terse     = 1;
    local $Data::Dumper::Indent    = 0;
    local $Data::Dumper::Sortkeys  = 1;
    local $Data::Dumper::Quotekeys = 0;
    my $rm = _response_model_pkg( $spec, $base, $op );
    my $h  = {
        operation_id   => $op->{operation_id},
        method         => $op->{method},
        path_template  => $op->{path},
        path_params    => $op->{path_params},
        query_params   => $op->{query_params},
        header_params  => $op->{header_params},
        has_body       => $op->{has_body} ? 1 : 0,
        response_model => $rm,
        response_is_array => $op->{response_is_array} ? 1 : 0,
    };
    my $d = Data::Dumper::Dumper($h);
    $d =~ s/^\$VAR1 = //;
    $d =~ s/;\s*\z//s;
    return $d;
}

sub _core_pm {
    my ( $pkg, $base, $sigs ) = @_;
    my $hmac_use = grep { $_ eq 'hmac' } @$sigs;
    my $bearer_use = grep { $_ eq 'bearer' } @$sigs;

    my $extra_use = '';
    my $auth_default = '[]';
    if ($hmac_use) {
        $extra_use .= "use ${base}::Auth::Plugin::Hmac;\n";
        $auth_default = "[ ${base}::Auth::Plugin::Hmac->new ]";
    }
    elsif ($bearer_use) {
        $extra_use .= "use ${base}::Auth::Plugin::Bearer;\n";
        $auth_default = "[ ${base}::Auth::Plugin::Bearer->new ]";
    }

    my $rc = "${base}::Client::Result";
    my $mid = <<"MID";
sub _build_openapi {
  my (\$self) = \@_;
  my \$file = \$self->openapi_schema_file
    // croak 'openapi_schema_file required to validate requests and responses';
  require YAML::PP;
  my \$data = YAML::PP->new( boolean => 'JSON::PP' )->load_file(\$file);
  return OpenAPI::Modern->new(
    openapi_uri => '/',
    openapi_schema => \$data,
  );
}

sub _request_validation_error {
  my ( \$self, \$meta, \$tx ) = \@_;
  return undef unless length( \$self->openapi_schema_file // '' );
  my \$vr = \$self->openapi->validate_request(
    \$tx->req,
    {
      path_template  => \$meta->{path_template},
      method         => \$meta->{method},
      operation_id   => \$meta->{operation_id},
    },
  );
  return undef if \$vr->valid;
  return 'OpenAPI request validation failed: ' . "\$vr";
}

sub _response_validation_error {
  my ( \$self, \$meta, \$tx ) = \@_;
  return undef unless length( \$self->openapi_schema_file // '' );
  my \$vr = \$self->openapi->validate_response(
    \$tx->res,
    {
      request       => \$tx->req,
      path_template => \$meta->{path_template},
      method        => \$meta->{method},
      operation_id  => \$meta->{operation_id},
    },
  );
  return undef if \$vr->valid;
  return 'OpenAPI response validation failed: ' . "\$vr";
}

sub request_sync {
  my ( \$self, \$meta, \$args ) = \@_;
  \$self->ua->blocking(1);
  my \$tx = \$self->build_tx( \$meta, \$args );
  \$self->_apply_auth(\$tx, \$meta);
  if ( my \$err = \$self->_request_validation_error( \$meta, \$tx ) ) {
    croak \$err;
  }
  \$self->ua->start(\$tx);
  return \$self->_result_from_tx( \$tx, \$meta );
}

sub request_p {
  my ( \$self, \$meta, \$args ) = \@_;
  \$self->ua->blocking(0);
  my \$tx = \$self->build_tx( \$meta, \$args );
  \$self->_apply_auth(\$tx, \$meta );
  if ( my \$err = \$self->_request_validation_error( \$meta, \$tx ) ) {
    return Mojo::Promise->reject(\$err);
  }
  return \$self->ua->start_p(\$tx)->then(
    sub (\$tx) {
      return \$self->_result_from_tx( \$tx, \$meta );
    }
  );
}

sub _result_from_tx {
  my ( \$self, \$tx, \$meta ) = \@_;
  if ( my \$err = \$self->_response_validation_error( \$meta, \$tx ) ) {
    croak \$err;
  }
  my \$data = \$self->_inflate_response( \$tx, \$meta );
  return ${rc}->new( tx => \$tx, data => \$data );
}

sub _inflate_response {
  my ( \$self, \$tx, \$meta ) = \@_;
  my \$code = \$tx->res->code // 0;
  return undef unless \$code >= 200 && \$code < 300;
  my \$ct = \$tx->res->headers->content_type // '';
  return undef unless \$ct =~ m{json}i;
  my \$json = \$tx->res->json;
  return undef unless defined \$json;
  my \$pkg = \$meta->{response_model} // '';
  return \$json if !length \$pkg;
  my \$ok = eval { require \$pkg; 1 };
  return \$json if !\$ok || !\$pkg->can('from_json');
  my \$out = eval { \$pkg->from_json( \$json, \$meta->{response_is_array} // 0 ) };
  return defined \$out ? \$out : \$json;
}

MID

    return <<"HEAD" . $mid . <<'CORE';
package $pkg;

use v5.26;
use Modern::Perl::Prelude -class;

use Moo;
use Types::Standard qw(Str ArrayRef InstanceOf);
use OpenAPI::Modern;
use Mojo::UserAgent;
use Mojo::URL;
use Mojo::JSON qw(encode_json);
use Mojo::Promise;
use Carp qw(croak);
use ${base}::Client::Result;
$extra_use

has base_url => (
  is       => 'ro',
  isa      => Str,
  required => 1,
);

has openapi_schema_file => (
  is  => 'ro',
  isa => Str,
);

has openapi => (
  is       => 'lazy',
  isa      => InstanceOf ['OpenAPI::Modern'],
  init_arg => undef,
);

has ua => (
  is      => 'lazy',
  isa     => InstanceOf ['Mojo::UserAgent'],
  default => sub { Mojo::UserAgent->new },
);

has auth_plugins => (
  is      => 'ro',
  isa     => ArrayRef,
  default => sub { $auth_default },
);

HEAD

sub build_tx {
  my ( $self, $meta, $args ) = @_;
  $args //= {};

  my $path = $meta->{path_template};
  for my $name ( @{ $meta->{path_params} // [] } ) {
    croak "missing path param '$name'" unless exists $args->{$name};
    my $v = $args->{$name};
    $path =~ s/\{\Q$name\E\}/$v/g;
  }

  my $url = Mojo::URL->new( $self->base_url . $path );
  my %q;
  for my $q ( @{ $meta->{query_params} // [] } ) {
    $q{$q} = $args->{$q} if exists $args->{$q};
  }
  $url->query( \%q ) if keys %q;

  my $headers = { Accept => 'application/json' };
  for my $h ( @{ $meta->{header_params} // [] } ) {
    $headers->{$h} = $args->{$h} if exists $args->{$h};
  }

  my $body;
  if ( $meta->{has_body} ) {
    my $payload = $args->{body} // croak 'body required';
    $headers->{'Content-Type'} //= 'application/json';
    $body = ref($payload) ? encode_json($payload) : $payload;
  }

  my $method = $meta->{method};
  return $self->ua->build_tx( $method => $url => $headers => $body );
}

sub _apply_auth {
  my ( $self, $tx, $meta ) = @_;
  for my $p ( @{ $self->auth_plugins } ) {
    $p->apply( $tx, $meta );
  }
}

1;
CORE
}

sub _ops_pm {
    my ( $pkg, $core_pkg, $ops, $sync, $async, $spec, $base ) = @_;
    my @methods;
    for my $op (@$ops) {
        my $sub = _sanitize_sub( $op->{operation_id} );
        my $meta = _meta_literal( $spec, $base, $op );
        push @methods, <<"SUB";
sub $sub {
  my ( \$self, \%args ) = \@_;
  my \$meta = $meta;
  return \$self->core->request_sync( \$meta, \\\%args ) if \$self->sync_mode;
  return \$self->core->request_p( \$meta, \\\%args );
}
SUB
    }

    my $body = join "\n", @methods;
    return <<"PM";
package $pkg;

use v5.26;
use Modern::Perl::Prelude -class;

use Moo::Role;
use Types::Standard qw(Bool InstanceOf);

requires 'core';

has sync_mode => (
  is       => 'ro',
  isa      => Bool,
  required => 1,
);

$body

1;
PM
}

sub _sync_pm {
    my ( $pkg, $ops_pkg, $core_pkg ) = @_;
    return <<"PM";
package $pkg;

use v5.26;
use Modern::Perl::Prelude -class;

use Moo;
use Types::Standard qw(InstanceOf);

has core => (
  is       => 'ro',
  isa      => InstanceOf ['$core_pkg'],
  required => 1,
);

with '$ops_pkg';

sub sync_mode { 1 }

1;
PM
}

sub _async_pm {
    my ( $pkg, $ops_pkg, $core_pkg ) = @_;
    return <<"PM";
package $pkg;

use v5.26;
use Modern::Perl::Prelude -class;

use Moo;
use Types::Standard qw(InstanceOf);

has core => (
  is       => 'ro',
  isa      => InstanceOf ['$core_pkg'],
  required => 1,
);

with '$ops_pkg';

sub sync_mode { 0 }

1;
PM
}

1;

__END__

=encoding utf8

=head1 NAME

Modern::OpenAPI::Generator::CodeGen::Client - Generate C<::Client::*> modules

=head1 DESCRIPTION

Emits C<Client::Core>, C<Client::Ops>, and optional C<Client::Sync> /
C<Client::Async> from the spec.

=head2 generate

Class method. Arguments include C<writer>, C<spec>, C<base>, C<sync>, C<async>,
C<signatures>.

=cut
