# NAME

Mojolicious::Plugin::Fondation::MigrationDBIx - Migration and fixture management for DBIx::Class backends

# VERSION

version 0.04

# SYNOPSIS

    # myapp.conf
    {
        'Fondation' => {
            dependencies => [
                { 'Fondation::Model::DBIx::Async' => {
                    backends => [ main => { ... } ],
                }},
                { 'Fondation::MigrationDBIx' => {
                    backend => 'main',    # optional -- uses DBIx::Async default
                }},
            ],
        },
    }

    # Commands
    $ myapp.pl db bootstrap-schema      # Create a minimal Schema class
    $ myapp.pl db prepare               # Generate SQL + copy fixtures from plugins
    $ myapp.pl db install               # Run pending migrations
    $ myapp.pl db upgrade               # Upgrade one version
    $ myapp.pl db downgrade             # Downgrade one version
    $ myapp.pl db status                # Show current migration version
    $ myapp.pl db populate [--set 1]    # Load fixture data

# DESCRIPTION

[Mojolicious::Plugin::Fondation::MigrationDBIx](https://metacpan.org/pod/Mojolicious%3A%3APlugin%3A%3AFondation%3A%3AMigrationDBIx) provides `db` commands for
managing database migrations and fixtures for DBIx::Class backends managed by
[Fondation::Model::DBIx::Async](https://metacpan.org/pod/Fondation%3A%3AModel%3A%3ADBIx%3A%3AAsync).

## Migration workflow

The typical workflow:

    myapp.pl db bootstrap-schema  # Step 0 (optional): create Schema class if none
    myapp.pl db prepare           # Step 1: generate SQL from schema classes
    myapp.pl db install           # Step 2: apply migrations to the database
    myapp.pl db populate          # Step 3: load initial data

For incremental changes, edit your schema, re-run `db prepare`, then
`db upgrade` / `db downgrade`.

## How it works

- **DBIx::Class::DeploymentHandler** with `ignore_ddl = 1`.
Upgrade and downgrade SQL are generated on-the-fly from `_source/` YAML files
-- no `db dump` step needed.
- **Backend resolution**: explicit `backend` config -> `default_backend` from
DBIx::Async -> first backend configured. Dies if no backend can be resolved.
- **Driver detection**: the database driver (SQLite, Pg, mysql) is parsed from
the DSN, never hardcoded.
- **Plugin fixtures**: `db prepare` scans all loaded plugins for
`share/fixtures/` directories and copies them to the app's `share/fixtures/`.
- **db populate** uses [DBIx::Class::Migration](https://metacpan.org/pod/DBIx%3A%3AClass%3A%3AMigration) to load fixture data from
`share/fixtures/VERSION/conf/*.json`.

## Plugin fixture discovery

Any Fondation plugin can ship fixtures in `share/fixtures/`. During
`db prepare`, they are copied to the application's `share/fixtures/`
directory. The directory structure is:

    share/fixtures/
    └── 1/                     # schema version
        ├── conf/
        │   └── my_set.json    # fixture set configuration
        └── my_set/
            └── my_table/
                └── 1.fix      # fixture data

# VERSION

0.01

# HELPERS

## schema\_drift

    my $drift = $c->schema_drift;

Returns a hashref describing schema changes since the last `db prepare`:

    { has_drift => 1, version => '2', changes => { users => { added => ['phone'] } } }

or `{ has_drift =` 0 }> if nothing changed. Reads the `.schema-sig.json`
file saved by `db prepare` and compares against the live schema signature
from ["schema\_sig" in Fondation::Model::DBIx::Async](https://metacpan.org/pod/Fondation%3A%3AModel%3A%3ADBIx%3A%3AAsync#schema_sig).

Used automatically at application startup via `fondation_finalyze`:
if a plugin Result class has changed (e.g. after a `cpanm` upgrade),
a warning is logged suggesting `db prepare -a && db upgrade`.
The application continues running -- the schema is not broken, just
out of sync with the migration files.

# CONFIGURATION

    'Fondation::MigrationDBIx' => {
        backend        => 'main',    # optional -- defaults to DBIx::Async default
        migrations_dir => '/path',   # optional -- defaults to <app>/share/migrations
    }

### backend

Name of the DBIx::Async backend to target. When omitted, falls back to
`default_backend` in DBIx::Async config, then to the first backend.

### migrations\_dir

Custom path for migration files. Defaults to `<app home>/share/migrations`.

# COMMANDS

All commands are invoked as `myapp.pl db COMMAND [OPTIONS]`.

## db bootstrap-schema \[--class ClassName\] \[--backend name\] \[--force\]

Creates a minimal [DBIx::Class::Schema](https://metacpan.org/pod/DBIx%3A%3AClass%3A%3ASchema) class file under `lib/`. Use this
when you have DBIx backends configured but no `schema_class` yet. After
creating the file, add `schema_class` to your backend config and run
`db prepare` to generate migration files.

The generated class uses `load_namespaces` to auto-discover any `Result`
classes under the application's `Schema::Result::*` namespace. Result
classes from Fondation plugins are registered separately by the `DBIx`
action before workers fork -- both mechanisms coexist transparently.

When both the application and a plugin define a `Result` class for the
same table, the application's class wins: `load_namespaces` runs during
`connect()`, _after_ the `DBIx` action has registered plugin sources.
This lets you extend or replace a plugin's Result class by defining your
own with the same `__PACKAGE__->table(...)`.

## db prepare \[-y\]

Generates SQL migration files from the schema classes and copies fixture
directories from all loaded plugins into the application. Use `-y` to
skip the overwrite prompt.

## db install

Runs all pending migrations. Creates the version storage table on first run.
If already at the latest version, prints a message and exits.

## db upgrade

Applies the next pending upgrade (one version at a time). Useful for testing
incremental migration steps.

## db downgrade

Rolls back the last applied migration (one version at a time).

## db status

Shows the current schema version (from source files) and the active database
version.

## db populate \[--set SET\]

Loads fixture data from `share/fixtures/VERSION/`. Use `--set` to filter
by set name. Defaults to loading all sets under version `1`.

# SEE ALSO

- [Mojolicious::Plugin::Fondation::Model::DBIx::Async](https://metacpan.org/pod/Mojolicious%3A%3APlugin%3A%3AFondation%3A%3AModel%3A%3ADBIx%3A%3AAsync) -- database backend plugin
- [DBIx::Class::DeploymentHandler](https://metacpan.org/pod/DBIx%3A%3AClass%3A%3ADeploymentHandler) -- migration engine
- [DBIx::Class::Migration](https://metacpan.org/pod/DBIx%3A%3AClass%3A%3AMigration) -- fixture loading

# AUTHOR

Daniel Brosseau <dab@cpan.org>

# COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by Daniel Brosseau.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.
