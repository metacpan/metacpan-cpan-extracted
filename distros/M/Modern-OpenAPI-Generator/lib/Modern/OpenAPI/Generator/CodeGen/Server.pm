package Modern::OpenAPI::Generator::CodeGen::Server;

use v5.26;
use strict;
use warnings;
use Carp qw(croak);
use YAML::PP ();

sub generate {
    my ( $class, %arg ) = @_;
    my $writer   = $arg{writer}   // croak 'writer';
    my $spec     = $arg{spec}     // croak 'spec';
    my $base     = $arg{base}     // croak 'base';
    my $skeleton   = $arg{skeleton}   // 0;
    my $local_test = $arg{local_test} // 0;
    my $ui         = $arg{ui}         // 1;

    my $lib = 'lib/' . _pathify_dir($base);

    my $augmented = $spec->clone_with_mojo_to('Controller');
    my $yaml      = YAML::PP->new( boolean => 'JSON::PP' )->dump_string($augmented);
    $writer->write( 'share/openapi.mojo.yaml', $yaml );

    my $server_pkg = "$base\::Server";

    $writer->write( "$lib/Server.pm", _server_pm_api( $server_pkg, $base, $ui ) );
    $writer->write(
        "$lib/Server/Controller.pm",
        _controller_pm( "$base\::Server::Controller", $base, $spec, $spec->operations,
            $skeleton, $local_test )
    );
    $writer->write( 'script/server.pl', _script_pm($base) );
}

# Same HTTP server entrypoint, but only serves share/openapi.yaml + Swagger UI (no REST API from spec).
sub generate_spec_ui_only {
    my ( $class, %arg ) = @_;
    my $writer = $arg{writer} // croak 'writer';
    my $spec   = $arg{spec}   // croak 'spec';
    my $base   = $arg{base}   // croak 'base';

    my $lib   = 'lib/' . _pathify_dir($base);
    my $title = $spec->title;
    $title =~ s/'/\\'/g;

    my $server_pkg = "$base\::Server";
    $writer->write( "$lib/Server.pm", _server_pm_spec_only( $server_pkg, $title ) );
    $writer->write( 'script/server.pl', _script_pm($base) );
}

sub _pathify_dir {
    my ($name) = @_;
    $name =~ s{::}{/}g;
    return $name;
}

sub _safe_operation_sub {
    my ($oid) = @_;
    $oid =~ s/[^A-Za-z0-9_]/_/g;
    return $oid;
}

# Full API (Mojolicious::Plugin::OpenAPI) + optional Swagger UI at /swagger
sub _server_pm_api {
    my ( $pkg, $base, $ui ) = @_;
    if ($ui) {
        return <<"PM";
package $pkg;

use v5.26;
use strict;
use warnings;

use Mojo::Base 'Mojolicious', -signatures;
use Storable qw(dclone);

sub startup (\$self) {
  \$self->routes->namespaces(['$base\::Server']);
  my \$spec = \$self->home->child('share', 'openapi.mojo.yaml');
  \$self->plugin(
    OpenAPI => {
      url   => \$spec->to_string,
      route => \$self->routes,
    }
  );
  \$self->helper(
    openapi_yaml_for_swagger_ui => sub (\$c) {
      state \$spec_data;
      if ( !\$spec_data ) {
        require YAML::PP;
        my \$p = \$c->app->home->child( 'share', 'openapi.mojo.yaml' );
        \$spec_data = YAML::PP->new( boolean => 'JSON::PP' )->load_file("\$p");
      }
      my \$doc = dclone(\$spec_data);
      if ( \$ENV{OAPI_SWAGGER_LOCAL_ORIGIN} ) {
        my \$u   = \$c->req->url->to_abs->clone;
        \$u->path('/');
        \$u->query(undef);
        my \$origin = \$u->to_string;
        \$origin =~ s{/\\z}{};
        my \$srv = \$doc->{servers};
        \$srv = [] unless ref \$srv eq 'ARRAY';
        my \$dup = 0;
        if (@\$srv) {
          my \$f = \$srv->[0];
          if ( ref \$f eq 'HASH' ) {
            ( my \$x = \$f->{url} // '' ) =~ s{/\\z}{};
            \$dup = 1 if \$x eq \$origin;
          }
        }
        unless (\$dup) {
          unshift @\$srv,
            {
              url         => \$origin,
              description => 'This server (request origin)',
            };
        }
        \$doc->{servers} = \$srv;
      }
      require YAML::PP;
      my \$yaml = YAML::PP->new( boolean => 'JSON::PP' )->dump_string(\$doc);
      \$c->res->headers->content_type('application/yaml; charset=UTF-8');
      \$c->render( text => \$yaml );
    }
  );
  \$self->routes->get(
    '/openapi.yaml' => sub (\$c) {
      \$c->openapi_yaml_for_swagger_ui;
    }
  );
  \$self->plugin(
    SwaggerUI => {
      route => \$self->routes->any('/swagger'),
      url   => '/openapi.yaml',
    }
  );
}

1;
PM
    }

    return <<"PM";
package $pkg;

use v5.26;
use strict;
use warnings;

use Mojo::Base 'Mojolicious', -signatures;

sub startup (\$self) {
  \$self->routes->namespaces(['$base\::Server']);
  my \$spec = \$self->home->child('share', 'openapi.mojo.yaml');
  \$self->plugin(
    OpenAPI => {
      url   => \$spec->to_string,
      route => \$self->routes,
    }
  );
}

1;
PM
}

# Only spec file + Swagger UI (e.g. --no-server --ui is not used; this is --no-server with ui)
sub _server_pm_spec_only {
    my ( $pkg, $title ) = @_;
    return <<"PM";
package $pkg;

use v5.26;
use strict;
use warnings;

use Mojo::Base 'Mojolicious', -signatures;
use Storable qw(dclone);

sub startup (\$self) {
  \$self->helper(
    openapi_yaml_for_swagger_ui => sub (\$c) {
      state \$spec_data;
      if ( !\$spec_data ) {
        require YAML::PP;
        my \$p = \$c->app->home->child( 'share', 'openapi.yaml' );
        \$spec_data = YAML::PP->new( boolean => 'JSON::PP' )->load_file("\$p");
      }
      my \$doc = dclone(\$spec_data);
      if ( \$ENV{OAPI_SWAGGER_LOCAL_ORIGIN} ) {
        my \$u   = \$c->req->url->to_abs->clone;
        \$u->path('/');
        \$u->query(undef);
        my \$origin = \$u->to_string;
        \$origin =~ s{/\\z}{};
        my \$srv = \$doc->{servers};
        \$srv = [] unless ref \$srv eq 'ARRAY';
        my \$dup = 0;
        if (@\$srv) {
          my \$f = \$srv->[0];
          if ( ref \$f eq 'HASH' ) {
            ( my \$x = \$f->{url} // '' ) =~ s{/\\z}{};
            \$dup = 1 if \$x eq \$origin;
          }
        }
        unless (\$dup) {
          unshift @\$srv,
            {
              url         => \$origin,
              description => 'This server (request origin)',
            };
        }
        \$doc->{servers} = \$srv;
      }
      require YAML::PP;
      my \$yaml = YAML::PP->new( boolean => 'JSON::PP' )->dump_string(\$doc);
      \$c->res->headers->content_type('application/yaml; charset=UTF-8');
      \$c->render( text => \$yaml );
    }
  );
  \$self->routes->get(
    '/openapi.yaml' => sub (\$c) {
      \$c->openapi_yaml_for_swagger_ui;
    }
  );
  \$self->plugin(
    SwaggerUI => {
      route => \$self->routes->any('/swagger'),
      url   => '/openapi.yaml',
      title => '$title',
    }
  );
}

1;
PM
}

sub _controller_pm {
    my ( $pkg, $base, $spec, $ops, $skeleton, $local_test ) = @_;
    my $stubdata_use =
      $local_test ? "use ${base}::StubData;\n" : '';
    my @subs;
    for my $op (@$ops) {
        my $oid = _safe_operation_sub( $op->{operation_id} );
        if ($local_test) {
            ( my $oid_q = $op->{operation_id} ) =~ s/'/\\'/g;
            push @subs, <<SUB;
sub $oid {
  my \$self = shift;
  return unless \$self->openapi->valid_input;
  my (\$st, \$body) = ${base}::StubData->for_operation('$oid_q');
  return \$self->render( status => \$st, json => \$body );
}
SUB
        }
        else {
            my $todo = $skeleton ? '' : "\n  # TODO: implement business logic for $oid\n";
            push @subs, <<SUB;
sub $oid {$todo
  my \$self = shift;
  return unless \$self->openapi->valid_input;
  \$self->stash(
    status  => 501,
    openapi => { errors => [ { message => 'Not implemented', path => '/' } ] },
  );
  return \$self->render;
}
SUB
        }
    }

    my $body = join "\n", @subs;
    return <<"PM";
package $pkg;

use v5.26;
use strict;
use warnings;

use Mojo::Base 'Mojolicious::Controller', -signatures;
$stubdata_use
$body

1;
PM
}

sub _script_pm {
    my ($base) = @_;
    return <<"SCRIPT";
#!/usr/bin/env perl
use v5.26;
use strict;
use warnings;
use FindBin qw(\$Bin);
use File::Spec;
BEGIN {
  \$ENV{MOJO_HOME} ||= File::Spec->catdir( \$Bin, '..' );
  unshift \@INC, File::Spec->catdir( \$Bin, '..', 'lib' );
  if ( grep { \$_ eq '--local-test' } \@ARGV ) {
    \$ENV{OAPI_SWAGGER_LOCAL_ORIGIN} = 1;
    \@ARGV = grep { \$_ ne '--local-test' } \@ARGV;
  }
}
use ${base}::Server;
${base}::Server->new->start(\@ARGV);
SCRIPT
}

1;

__END__

=encoding utf8

=head1 NAME

Modern::OpenAPI::Generator::CodeGen::Server - Generate Mojolicious server and controller

=head1 DESCRIPTION

Writes C<::Server>, C<::Server::Controller>, C<script/server.pl>, and
F<share/openapi.mojo.yaml> for L<Mojolicious::Plugin::OpenAPI>.

=head2 generate

Full server mode: REST API from the spec, optional Swagger UI, optional
C<--local-test> stubs.

=head2 generate_spec_ui_only

Serves the spec and Swagger UI only (no generated controller routes).

=cut
