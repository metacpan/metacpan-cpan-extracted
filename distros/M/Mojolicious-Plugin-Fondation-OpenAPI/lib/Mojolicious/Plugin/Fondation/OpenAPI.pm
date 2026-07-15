package Mojolicious::Plugin::Fondation::OpenAPI;
$Mojolicious::Plugin::Fondation::OpenAPI::VERSION = '0.02';
use Mojo::Base 'Mojolicious::Plugin', -signatures;


use Mojo::JSON qw(decode_json);
use Mojo::File 'path';

# ABSTRACT: OpenAPI specification generator and runtime validator for Fondation applications

sub fondation_meta {
    return {
        dependencies => ['Fondation::Model::DBIx::Async', 'Fondation::Problem'],
        after        => ['Fondation::MigrationDBIx'],
        defaults     => {
            backend           => undef,
            fondation_init    => [
                ['openapi', 'generate', '-y'],
                ['openapi', 'sync-permissions', '-q'],
            ],
            fondation_upgrade => [
                ['openapi', 'generate', '-y'],
                ['openapi', 'sync-permissions', '-q'],
            ],
            fondation_clean   => [
                'share/openapi.json',
                'public/js/validators.js',
            ],
        },
    };
}


sub register ($self, $app, $conf = {}) {
    $app->defaults('openapi.config' => {
        backend => $conf->{backend},
        schemas => $conf->{schemas} // {},
    });

    push @{$app->commands->namespaces},
        'Mojolicious::Plugin::Fondation::OpenAPI::Command';

    return $self;
}

sub fondation_finalyze ($self, $app, $long_name) {
    my $spec_file = $app->home->child('share', 'openapi.json');

    unless (-f $spec_file) {
        $self->log->warn(
            "No spec found at $spec_file. "
            . "Run 'openapi generate' first."
        );
        return;
    }

    # Skip during 'fondation refresh' — the clean phase will remove the spec,
    # then 'openapi generate -y' in the init phase will rebuild from scratch.
    if (grep { $_ eq 'refresh' } @ARGV) {
        $self->log->debug("Skipping OpenAPI load during fondation refresh");
        return;
    }

    # Apply route-level requires() from x-auth in the OpenAPI spec.
    # Hook MUST be registered BEFORE loading OpenAPI so it fires during _add_routes.
    # Override conditions with mode-aware handling via $c->problem().
    $app->plugins->on(openapi_routes_added => sub {
        my ($openapi, $routes) = @_;
        $routes ||= [];

        # Override conditions with mode-aware handling via $c->problem().
        # API routes auto-detected via openapi.path in match stack.
        for my $cond (qw(fondation.perm fondation.group)) {
            $app->routes->add_condition($cond => sub {
                my ($route, $c, $captures, $value) = @_;
                my $method = $cond eq 'fondation.perm'
                    ? 'check_perm' : 'check_group';
                return 1 if $c->$method($value);

                my $label = $cond eq 'fondation.perm'
                    ? 'Permission' : 'Group';
                $c->problem(
                    status => 403,
                    title  => 'Forbidden',
                    detail => "$label '$value' required",
                );
                return undef;
            });
        }

        for my $r (@$routes) {
            my $defaults = $r->pattern->defaults;
            my $path     = $defaults->{'openapi.path'};
            my $method   = $defaults->{'openapi.method'};
            next unless $path && $method;

            my $op_spec = $openapi->validator->get([paths => $path, $method]);
            my $x_auth  = $op_spec->{'x-auth'} // {};

            my @conditions;
            push @conditions, 'fondation.perm'  => $_ for @{$x_auth->{permissions} // []};
            push @conditions, 'fondation.group' => $_ for @{$x_auth->{groups}     // []};
            $r->requires(@conditions) if @conditions;
        }
    });

    # Load the OpenAPI plugin with the generated spec.
    # No Security sub-plugin — x-auth is translated into route-level requires() above.
    $app->plugin(OpenAPI => {
        url => $spec_file->to_string,
    });
    $self->log->debug("OpenAPI plugin loaded from $spec_file");

    # Swagger UI in development mode
    if ($app->mode eq 'development') {
        $app->routes->get('/swagger')->to(cb => sub {
            my $c = shift;
            $c->stash(openapi_url => '/openapi.json');
            $c->render(template => 'swagger');
        });

        $app->routes->get('/openapi.json')->to(cb => sub {
            my $c = shift;
            $c->render(json => decode_json($spec_file->slurp));
        });
    }
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Mojolicious::Plugin::Fondation::OpenAPI - OpenAPI specification generator and runtime validator for Fondation applications

=head1 VERSION

version 0.02

=head1 SYNOPSIS

  # In myapp.conf
  'Fondation::OpenAPI' => {
      backend => 'main',
      schemas => {
          User => {
              columns => {
                  password => {
                      writeOnly => 1,
                      create    => { required => 1 },
                      update    => { required => 0 },
                  },
              },
          },
      },
  }

  # CLI
  $ myapp.pl openapi generate
  $ myapp.pl openapi generate -y
  $ myapp.pl openapi generate --output custom.json

=head1 DESCRIPTION

This plugin provides the C<openapi generate> command to produce an
OpenAPI 3.0.3 specification from DBIx::Class sources. At runtime,
C<fondation_finalyze> loads the generated C<share/openapi.json> via
L<Mojolicious::Plugin::OpenAPI> for request validation and adds
Swagger UI routes in development mode.

=head1 CONFIGURATION

=head2 Plugin config

  'Fondation::OpenAPI' => {
      backend => 'main',          # optional -- falls back to DBIx::Async default
      schemas => { ... },         # optional -- column overrides
  }

=head2 Backend resolution

The backend name is resolved in this order:

=over

=item 1. OpenAPI's own C<backend> config

=item 2. DBIx::Async's C<default_backend> config key

=item 3. First backend in DBIx::Async's C<backends> array

=back

=head2 Schema config override

Any column property can be overridden via C<schemas> without modifying
DBIx Result classes. See L<Mojolicious::Plugin::Fondation::OpenAPI::Command::openapi>
for the full list of supported keys.

=head2 x-auth config override

Permission annotations on CRUD endpoints can be overridden via C<x_auth>
in the C<schemas> config. The default convention is
C<{moniker_lc}_{operation}> (e.g., C<user_create>, C<group_list>).

  'Fondation::OpenAPI' => {
      schemas => {
          User => {
              x_auth => {
                  create => {
                      permissions => ['admin_create_user'],
                      groups      => ['admins'],
                  },
                  list => {
                      permissions => [],   # public endpoint
                  },
              },
          },
      },
  }

Overrides replace the default entirely. An empty C<permissions> array
makes the endpoint public (no C<x-auth> in the generated spec).
Additional constraint keys (C<groups>, C<features>, etc.) are translated
into C<requires()> route conditions at startup via the C<openapi_routes_added> hook.

=head2 openapi_exclude in plugin C<fondation_meta>

Plugins can declare tables that should be excluded from the generated
OpenAPI spec via C<openapi_exclude> in their C<fondation_meta>. This
is the canonical way to hide internal tables (pivot tables, audit logs,
etc.) that should never be exposed as public API endpoints.

  # In any Fondation plugin's fondation_meta:
  sub fondation_meta {
      return {
          defaults => {
              openapi_exclude => ['UserGroup'],
          },
      };
  }

Each entry is a DBIx::Class source moniker (class-derived name, e.g. C<UserGroup>),
matching the C<register_source> moniker used by Action::DBIx.
Excluded sources produce no CRUD
routes, no OpenAPI schemas, and no C<public/js/validators.js> entries.

B<Design:> The mechanism lives in plugin C<fondation_meta> rather than
in the OpenAPI plugin config because the plugin that owns the table
knows best whether it should be exposed. This follows the Fondation
principle of self-contained bricks — the OpenAPI plugin only reads
what other plugins declare.

=head1 DEPENDENCIES

This plugin requires L<Fondation::Model::DBIx::Async>.

Transitively, it depends on L<Mojolicious::Plugin::OpenAPI> E<gt>= 5.12,
which requires L<JSON::Validator> E<gt>= 5.17.

=head2 Perl 5.40 Incompatibility

On Perl E<gt>= 5.40, L<Net::IDN::Encode> (a dependency of JSON::Validator
5.17+) fails to compile because its XS code calls C<uvuni_to_utf8_flags>,
removed from the Perl C API in 5.40. This cascades:

  Net::IDN::Encode → compile FAIL (Perl ≥ 5.40)
    → JSON::Validator 5.17+ → blocked by cpanm
      → Mojolicious::Plugin::OpenAPI 5.12 → blocked

B<Workaround on Debian:> the C<libnet-idn-encode-perl> package provides
a pre-compiled version that works on Perl 5.40:

  apt install libnet-idn-encode-perl

=head1 COMMANDS

=head2 openapi generate

Generates C<share/openapi.json> and C<public/js/validators.js> from
DBIx::Class sources discovered via the configured backend.

Options: C<-y> (overwrite without prompt), C<--output> (custom path).

=head1 RUNTIME

On startup (C<fondation_finalyze>), if C<share/openapi.json> exists it
is loaded via L<Mojolicious::Plugin::OpenAPI> for request validation.
C<x-auth> permissions and groups are translated into route-level
C<requires('fondation.perm')> and C<requires('fondation.group')>
conditions via the C<openapi_routes_added> hook, unifying protection
with HTML routes.
Swagger UI routes (C</swagger> and C</openapi.json>) are added in
development mode. If the spec is missing, a warning is logged and
startup continues.

=head1 OUTPUT FILES

=over

=item C<share/openapi.json>

OpenAPI 3.0.3 specification with API Base schemas, contextual
projections (only when different), and CRUD paths. Committed to the
application repository.

=item C<public/js/validators.js>

Client-side form validation via C<FondationValidators.validate()>.
Consumed by L<Fondation::Asset> bundles. Committed to the application
repository.

=back

Always run C<openapi generate> before C<asset generate>.

=head1 SEE ALSO

L<Mojolicious::Plugin::Fondation::OpenAPI::Command::openapi>,
L<Fondation::Model::DBIx::Async>,
L<Mojolicious::Plugin::OpenAPI>

=head1 AUTHOR

Daniel Brosseau <dab@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by Daniel Brosseau.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
