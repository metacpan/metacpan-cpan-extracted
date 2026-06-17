package Mojolicious::Plugin::Fondation::MigrationDBIx;
$Mojolicious::Plugin::Fondation::MigrationDBIx::VERSION = '0.01';
# ABSTRACT: Migration and fixture management for DBIx::Class backends

use Mojo::Base 'Mojolicious::Plugin', -signatures;

use Mojo::File 'path';
use JSON::MaybeXS;

sub fondation_meta {
    return {
        dependencies => ['Fondation::Model::DBIx::Async'],
        defaults     => {
            title             => 'DBIx Database Migration',
            fondation_init    => [
                ['db', 'prepare', '-y'],
                ['db', 'install'],
                ['db', 'populate'],
            ],
            fondation_upgrade => [
                ['db', 'prepare', '-y', '-a'],
                ['db', 'upgrade'],
            ],
            fondation_clean   => ['data/app.db'],
        },
    };
}

sub register ($self, $app, $config) {

    my $backend_name = $config->{backend};

    my $migrations_dir = $config->{migrations_dir}
        // $app->home->child('share', 'migrations')->to_string;

    my $sig_file = path($migrations_dir)->child('.schema-sig.json')->to_string;

    $app->defaults('migration_dbix.config' => {
        backend        => $backend_name,
        migrations_dir => $migrations_dir,
        sig_file       => $sig_file,
    });

    push @{$app->commands->namespaces},
        'Mojolicious::Plugin::Fondation::MigrationDBIx::Command';

    # Helper: schema_drift() -- detect schema changes since last prepare
    $app->helper(schema_drift => sub ($c) {
        my $cfg = $app->defaults->{'migration_dbix.config'};

        # Build a native schema (no async workers) for inspection
        require Mojolicious::Plugin::Fondation::MigrationDBIx::Command::db;
        my $native = Mojolicious::Plugin::Fondation::MigrationDBIx::Command::db
            ->_build_native_schema($app, $cfg);
        return unless $native;

        my $live_sig = $c->schema_sig($native);
        my $stored   = $self->_load_sig($cfg->{sig_file});

        # Disconnect the native schema -- we only needed it for inspection
        $native->storage->disconnect if $native->storage;

        return { has_drift => 0, version => $stored->{version} // '?' }
            unless $stored;

        my $changes = $self->_sig_diff($stored->{sources}, $live_sig);

        return {
            has_drift => !!(%$changes),
            version   => $stored->{version} // '?',
            changes   => $changes,
        };
    });

    return $self;
}

sub fondation_finalyze ($self, $app, $long_name) {
    return 1 unless $app->has_helper('schema_drift');

    my $c = $app->build_controller;
    my $drift = eval { $c->schema_drift };
    return 1 unless $drift && $drift->{has_drift};

    my @changed = sort keys %{$drift->{changes}};
    $app->log->warn(sprintf(
        '[Fondation::MigrationDBIx] Schema drifted in sources: %s',
        join(', ', @changed)));
    $app->log->warn(sprintf(
        '[Fondation::MigrationDBIx] Version %s. Run: db prepare -a && db upgrade',
        $drift->{version}));
    return 1;
}

# Load the stored schema signature from disk
sub _load_sig ($self, $sig_file) {
    return undef unless -f $sig_file;
    my $data = eval { path($sig_file)->slurp };
    return undef unless $data;
    my $sig = eval { decode_json($data) };
    return undef unless $sig && $sig->{sources};
    return $sig;
}

# Compare two schema signatures and return changed sources
sub _sig_diff ($self, $stored_sources, $live_sources) {
    my $changes = {};

    # Sources in live but not stored -> new tables
    for my $name (keys %$live_sources) {
        unless (exists $stored_sources->{$name}) {
            $changes->{$name} = 'new';
        }
    }

    # Sources in stored but not live -> removed tables
    for my $name (keys %$stored_sources) {
        unless (exists $live_sources->{$name}) {
            $changes->{$name} = 'removed';
        }
    }

    # Sources in both -> check column-level changes
    for my $name (keys %$live_sources) {
        next if $changes->{$name};
        next unless $stored_sources->{$name};
        my $diff = $self->_sig_diff_source(
            $stored_sources->{$name}, $live_sources->{$name});
        $changes->{$name} = $diff if $diff && _source_diff_has_changes($diff);
    }

    return $changes;
}

# Compare a single source between stored and live
sub _sig_diff_source ($self, $stored, $live) {
    my $diff = { added => [], removed => [], modified => {} };

    my %stored_cols = map { $_->{name} => $_ } @{$stored->{columns}};
    my %live_cols   = map { $_->{name} => $_ } @{$live->{columns}};

    # Added columns
    for my $name (sort keys %live_cols) {
        push @{$diff->{added}}, $name unless exists $stored_cols{$name};
    }

    # Removed columns
    for my $name (sort keys %stored_cols) {
        push @{$diff->{removed}}, $name unless exists $live_cols{$name};
    }

    # Modified columns
    for my $name (sort keys %live_cols) {
        next unless exists $stored_cols{$name};
        my $s = $stored_cols{$name};
        my $l = $live_cols{$name};
        my %mod;
        for my $attr (qw(data_type is_nullable is_auto_increment
            default_value size is_foreign_key))
        {
            my $sv = $s->{$attr};
            my $lv = $l->{$attr};
            next if !defined($sv) && !defined($lv);
            next if  defined($sv) &&  defined($lv) && _eq_deep($sv, $lv);
            $mod{$attr} = [$sv, $lv];
        }
        $diff->{modified}{$name} = \%mod if %mod;
    }

    # PK changes
    my %stored_pk = map { $_ => 1 } @{$stored->{primary_keys}};
    my %live_pk   = map { $_ => 1 } @{$live->{primary_keys}};
    if (join(',', sort keys %stored_pk) ne join(',', sort keys %live_pk)) {
        $diff->{primary_keys} = [
            [sort keys %stored_pk],
            [sort keys %live_pk],
        ];
    }

    return $diff;
}

# Deep equality for nested structures (arrays, hashes, scalars)
sub _eq_deep {
    my ($a, $b) = @_;
    return 0 if ref $a ne ref $b;
    return $a eq $b if !ref $a;
    if (ref $a eq 'ARRAY') {
        return 0 if @$a != @$b;
        for my $i (0 .. $#$a) {
            return 0 unless _eq_deep($a->[$i], $b->[$i]);
        }
        return 1;
    }
    if (ref $a eq 'HASH') {
        return 0 if keys %$a != keys %$b;
        for my $k (keys %$a) {
            return 0 unless exists $b->{$k} && _eq_deep($a->{$k}, $b->{$k});
        }
        return 1;
    }
    return 0;
}

# Check if a source diff has any actual changes
sub _source_diff_has_changes {
    my ($diff) = @_;
    return 1 if @{$diff->{added}};
    return 1 if @{$diff->{removed}};
    return 1 if %{$diff->{modified}};
    return 1 if $diff->{primary_keys};
    return 0;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Mojolicious::Plugin::Fondation::MigrationDBIx - Migration and fixture management for DBIx::Class backends

=head1 VERSION

version 0.01

=head1 SYNOPSIS

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

=head1 DESCRIPTION

L<Mojolicious::Plugin::Fondation::MigrationDBIx> provides C<db> commands for
managing database migrations and fixtures for DBIx::Class backends managed by
L<Fondation::Model::DBIx::Async>.

=head2 Migration workflow

The typical workflow:

  myapp.pl db bootstrap-schema  # Step 0 (optional): create Schema class if none
  myapp.pl db prepare           # Step 1: generate SQL from schema classes
  myapp.pl db install           # Step 2: apply migrations to the database
  myapp.pl db populate          # Step 3: load initial data

For incremental changes, edit your schema, re-run C<db prepare>, then
C<db upgrade> / C<db downgrade>.

=head2 How it works

=over

=item *

B<DBIx::Class::DeploymentHandler> with C<ignore_ddl = 1>.
Upgrade and downgrade SQL are generated on-the-fly from C<_source/> YAML files
-- no C<db dump> step needed.

=item *

B<Backend resolution>: explicit C<backend> config -> C<default_backend> from
DBIx::Async -> first backend configured. Dies if no backend can be resolved.

=item *

B<Driver detection>: the database driver (SQLite, Pg, mysql) is parsed from
the DSN, never hardcoded.

=item *

B<Plugin fixtures>: C<db prepare> scans all loaded plugins for
C<share/fixtures/> directories and copies them to the app's C<share/fixtures/>.

=item *

B<db populate> uses L<DBIx::Class::Migration> to load fixture data from
C<share/fixtures/VERSION/conf/*.json>.

=back

=head2 Plugin fixture discovery

Any Fondation plugin can ship fixtures in C<share/fixtures/>. During
C<db prepare>, they are copied to the application's C<share/fixtures/>
directory. The directory structure is:

  share/fixtures/
  └── 1/                     # schema version
      ├── conf/
      │   └── my_set.json    # fixture set configuration
      └── my_set/
          └── my_table/
              └── 1.fix      # fixture data

=head1 VERSION

0.01

=head1 HELPERS

=head2 schema_drift

  my $drift = $c->schema_drift;

Returns a hashref describing schema changes since the last C<db prepare>:

  { has_drift => 1, version => '2', changes => { users => { added => ['phone'] } } }

or C<{ has_drift => 0 }> if nothing changed. Reads the C<.schema-sig.json>
file saved by C<db prepare> and compares against the live schema signature
from L<Fondation::Model::DBIx::Async/schema_sig>.

Used automatically at application startup via C<fondation_finalyze>:
if a plugin Result class has changed (e.g. after a C<cpanm> upgrade),
a warning is logged suggesting C<db prepare -a && db upgrade>.
The application continues running -- the schema is not broken, just
out of sync with the migration files.

=head1 CONFIGURATION

  'Fondation::MigrationDBIx' => {
      backend        => 'main',    # optional -- defaults to DBIx::Async default
      migrations_dir => '/path',   # optional -- defaults to <app>/share/migrations
  }

=head3 backend

Name of the DBIx::Async backend to target. When omitted, falls back to
C<default_backend> in DBIx::Async config, then to the first backend.

=head3 migrations_dir

Custom path for migration files. Defaults to C<E<lt>app homeE<gt>/share/migrations>.

=head1 COMMANDS

All commands are invoked as C<myapp.pl db COMMAND [OPTIONS]>.

=head2 db bootstrap-schema [--class ClassName] [--backend name] [--force]

Creates a minimal L<DBIx::Class::Schema> class file under C<lib/>. Use this
when you have DBIx backends configured but no C<schema_class> yet. After
creating the file, add C<schema_class> to your backend config and run
C<db prepare> to generate migration files.

The generated class uses C<load_namespaces> to auto-discover any C<Result>
classes under the application's C<Schema::Result::*> namespace. Result
classes from Fondation plugins are registered separately by the C<DBIx>
action before workers fork -- both mechanisms coexist transparently.

When both the application and a plugin define a C<Result> class for the
same table, the application's class wins: C<load_namespaces> runs during
C<connect()>, I<after> the C<DBIx> action has registered plugin sources.
This lets you extend or replace a plugin's Result class by defining your
own with the same C<< __PACKAGE__->table(...) >>.

=head2 db prepare [-y]

Generates SQL migration files from the schema classes and copies fixture
directories from all loaded plugins into the application. Use C<-y> to
skip the overwrite prompt.

=head2 db install

Runs all pending migrations. Creates the version storage table on first run.
If already at the latest version, prints a message and exits.

=head2 db upgrade

Applies the next pending upgrade (one version at a time). Useful for testing
incremental migration steps.

=head2 db downgrade

Rolls back the last applied migration (one version at a time).

=head2 db status

Shows the current schema version (from source files) and the active database
version.

=head2 db populate [--set SET]

Loads fixture data from C<share/fixtures/VERSION/>. Use C<--set> to filter
by set name. Defaults to loading all sets under version C<1>.

=head1 SEE ALSO

=over

=item *

L<Mojolicious::Plugin::Fondation::Model::DBIx::Async> -- database backend plugin

=item *

L<DBIx::Class::DeploymentHandler> -- migration engine

=item *

L<DBIx::Class::Migration> -- fixture loading

=back

=head1 AUTHOR

Daniel Brosseau <dab@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by Daniel Brosseau.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
