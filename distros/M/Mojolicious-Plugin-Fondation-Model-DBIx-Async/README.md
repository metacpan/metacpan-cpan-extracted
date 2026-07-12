# NAME

Mojolicious::Plugin::Fondation::Model::DBIx::Async - Fondation plugin exposing DBIx::Class::Async natively

# VERSION

version 0.03

# SYNOPSIS

    # myapp.conf
    {
        'Fondation' => {
            dependencies => [
                { 'Fondation::Model::DBIx::Async' => {
                    backends => [
                        main => {
                            dsn          => 'dbi:SQLite:dbname=data/app.db',
                            schema_class => 'MySchema',
                            workers      => 2,
                        },
                    ],
                    models => {
                        user => { source => 'User' },
                    },
                }},
            ],
        },
    }

    # In a controller
    sub list ($self) {
        $self->render_later;
        $self->model('user')->search({ active => 1 })->all
            ->on_done(sub {
                my @users = @_;
                $self->render(json => [ map { $_->get_columns } @users ]);
            })
            ->on_fail(sub { $self->reply->exception(shift) })
            ->retain;
    }

# DESCRIPTION

[Mojolicious::Plugin::Fondation::Model::DBIx::Async](https://metacpan.org/pod/Mojolicious%3A%3APlugin%3A%3AFondation%3A%3AModel%3A%3ADBIx%3A%3AAsync) is a [Fondation](https://metacpan.org/pod/Fondation) plugin
that exposes [DBIx::Class::Async](https://metacpan.org/pod/DBIx%3A%3AClass%3A%3AAsync) natively — no hashref CRUD wrapper, no
Future-to-Mojo::Promise conversion. Every call goes through a background worker
pool, keeping the [Mojolicious](https://metacpan.org/pod/Mojolicious) event loop responsive.

## Architecture

    ┌─────────────────────────────────────────────────┐
    │  Mojolicious Application                        │
    │  $c->model('user') → ResultSet                  │
    │  $c->schema         → DBIx::Class::Async::Schema│
    └──────────────┬──────────────────────────────────┘
                   │ IO::Async::Loop::Mojo
    ┌──────────────▼──────────────────────────────────┐
    │  Worker Pool (forked processes)                 │
    │  ┌────────┐ ┌────────┐ ┌────────┐              │
    │  │Worker 1│ │Worker 2│ │Worker N│              │
    │  └────────┘ └────────┘ └────────┘              │
    └──────────────┬──────────────────────────────────┘
                   │ DBI
    ┌──────────────▼──────────────────────────────────┐
    │  Database                                       │
    └─────────────────────────────────────────────────┘

Each backend is a separate [DBIx::Class::Async::Schema](https://metacpan.org/pod/DBIx%3A%3AClass%3A%3AAsync%3A%3ASchema) with its own
[IO::Async::Loop::Mojo](https://metacpan.org/pod/IO%3A%3AAsync%3A%3ALoop%3A%3AMojo) and worker pool. Workers are forked lazily on
the first schema access and are automatically stopped on process exit.

## Model discovery

During `fondation_finalyze`, the plugin scans every loaded Fondation plugin
for a `models` key in their configuration. Models declared by dependency
plugins are merged, with the application configuration taking priority.
Each model is validated to have a resolvable backend.

## Source registration

The `DBIx` action ([Mojolicious::Plugin::Fondation::Model::DBIx::Async::Action::DBIx](https://metacpan.org/pod/Mojolicious%3A%3APlugin%3A%3AFondation%3A%3AModel%3A%3ADBIx%3A%3AAsync%3A%3AAction%3A%3ADBIx))
auto-discovers `Result` and `ResultSet` classes under each plugin's
`Schema::Result::*` and `Schema::ResultSet::*` namespaces and registers them
on the native schema class _before_ workers are forked.

## Shutdown

An `END` block disconnects all schemas on clean process exit (Ctrl-C, `kill`,
`systemctl stop`), calling ["disconnect" in DBIx::Class::Async](https://metacpan.org/pod/DBIx%3A%3AClass%3A%3AAsync#disconnect) to gracefully
stop worker processes. The `before_server_stop` hook is also emitted so
other code can react to shutdown. Only `SIGKILL` bypasses this — no hook
can help there.

# CONFIGURATION

    'Fondation::Model::DBIx::Async' => {
        backends => [
            main => {
                dsn          => 'dbi:SQLite:dbname=data/app.db',
                schema_class => 'MySchema',
                user         => '',           # optional
                pass         => '',           # optional
                workers      => 2,            # default: 2
                dbi_attrs    => {},           # optional
            },
            logs => {
                dsn          => 'dbi:SQLite:dbname=data/logs.db',
                schema_class => 'MyLogSchema',
                workers      => 1,
            },
        ],
        default_backend => 'main',            # optional
        models => {
            user    => { source => 'User' },
            article => { source => 'articles', backend => 'main' },
            log     => { source => 'logs',    backend => 'logs' },
        },
    },

### backends

Array of name/config pairs (ordered). Each pair provides a backend name
followed by its configuration hash. Each backend requires `dsn` and
`schema_class`. Names are used by models and other plugins
to reference a specific connection.

Plain DSN strings are accepted as a shorthand and normalized to
`{ dsn => $dsn }`.

### default\_backend

Name of the default backend. When omitted, the first backend in the
`backends` array is used. Models without an explicit `backend` fall
back to this.

### models

Hash of model definitions. Each model maps a name to a database source
(table name). The `backend` key is optional — it defaults to
`default_backend` or the first configured backend.

# HELPERS

All helpers are available on the controller object (`$c`).

## schema\_class

    my $class = $c->schema_class;              # from first backend with schema_class
    my $class = $c->schema_class('backend');   # from a specific backend

Returns the schema class name string, without connecting.

## schema

    my $schema = $c->schema;                   # first backend
    my $schema = $c->schema('backend');        # specific backend

Returns a [DBIx::Class::Async::Schema](https://metacpan.org/pod/DBIx%3A%3AClass%3A%3AAsync%3A%3ASchema) instance. Creates it on first access
(lazy, cached per backend). Workers are forked only when the schema is first
connected.

## model

    my $rs = $c->model('user');                # DBIx::Class::Async::ResultSet

Returns a [DBIx::Class::Async::ResultSet](https://metacpan.org/pod/DBIx%3A%3AClass%3A%3AAsync%3A%3AResultSet) for the named model. The model
must be declared in configuration. All DML (`search`, `create`, `update`,
`delete`, `find`) goes through the worker pool and returns [Future](https://metacpan.org/pod/Future) objects.

    # Search
    $c->model('user')->search({ active => 1 })->all
        ->on_done(sub { my @users = @_; ... })
        ->on_fail(sub { my $err = shift; ... })
        ->retain;

Always end Future chains with `->retain` to prevent garbage collection
before the async worker responds.

## model\_config

    my $cfg = $c->model_config('user');
    # { name => 'user', source => 'User', backend => 'main' }

Returns model metadata.

## model\_list

    my $names = $c->model_list;                # ['article', 'user']

Returns a sorted arrayref of configured model names.

## backend\_config

    my $cfg = $c->backend_config;              # first backend
    my $cfg = $c->backend_config('main');
    # { dsn => '...', schema_class => '...', name => 'main', ... }

Returns the full backend configuration hash (including the `name` key).
Used by other plugins (MigrationDBIx, OpenAPI) to discover connection details.

## default\_backend\_name

    my $name = $c->default_backend_name;       # 'main'
    my $name = $c->default_backend_name('logs');   # explicit wins

Cascade: explicit parameter → `default_backend` config → first backend
→ `undef`.

# PLUGIN INTEGRATION

Plugins that provide DBIC Result classes must declare their `fondation_meta`:

    sub fondation_meta {
        return {
            dependencies => ['Fondation::Model::DBIx::Async'],
            defaults => {
                models => {
                    user => {
                        source  => 'users',
                        backend => undef,   # resolves to default
                    },
                },
            },
        };
    }

The `DBIx` action will then auto-discover `Schema::Result::*` and
`Schema::ResultSet::*` classes under the plugin's namespace and register
them on the schema.

# SEE ALSO

- [Mojolicious::Plugin::Fondation](https://metacpan.org/pod/Mojolicious%3A%3APlugin%3A%3AFondation) — the Fondation plugin loader
- [Mojolicious::Plugin::Fondation::MigrationDBIx](https://metacpan.org/pod/Mojolicious%3A%3APlugin%3A%3AFondation%3A%3AMigrationDBIx) — database migrations
- [DBIx::Class::Async](https://metacpan.org/pod/DBIx%3A%3AClass%3A%3AAsync) — async worker-pool wrapper for DBIC
- [DBIx::Class::Async::Schema](https://metacpan.org/pod/DBIx%3A%3AClass%3A%3AAsync%3A%3ASchema) — async schema with forked workers

# AUTHOR

Daniel Brosseau <dab@cpan.org>

# COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by Daniel Brosseau.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.
