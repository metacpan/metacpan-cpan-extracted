package Mojolicious::Plugin::Fondation::MigrationDBIx::Command::db;
$Mojolicious::Plugin::Fondation::MigrationDBIx::Command::db::VERSION = '0.03';
# ABSTRACT: Database migration and fixture commands for DBIx::Class backends

use Mojo::Base 'Mojolicious::Command', -signatures;

use Mojo::File 'path';
use JSON::MaybeXS;

has description => 'Manage database migrations and fixtures for DBIx backends';
has usage       => sub ($self) {
    <<"USAGE";
Usage: APPLICATION db COMMAND [OPTIONS]

  myapp.pl db bootstrap-schema [--class ClassName] [--backend name] [--force]
                                    Create a minimal DBIx::Class::Schema class
  myapp.pl db prepare [-y] [-a]     Generate SQL migrations + copy fixtures
                                    -a  Auto-bump schema version on drift
  myapp.pl db install               Run pending DBIx migrations
  myapp.pl db upgrade               Upgrade one version
  myapp.pl db downgrade             Downgrade one version
  myapp.pl db status                Show current migration version
  myapp.pl db populate [--set SET] [--force]
                                    Load DBIx fixture data (current DB version)
                                    --force  Reload already-loaded sets

USAGE
};

sub run ($self, @args) {
    my $app = $self->app;
    my $subcommand = shift @args || '';

    my $config = $app->defaults->{'migration_dbix.config'}
        or die "MigrationDBIx not configured. Add Fondation::MigrationDBIx to your config.\n";

    for ($subcommand) {
        /^bootstrap-schema$/ and return $self->_bootstrap_schema($app, $config, @args);
        /^install$/   and return $self->_install($app, $config, @args);
        /^upgrade$/   and return $self->_upgrade($app, $config, @args);
        /^downgrade$/ and return $self->_downgrade($app, $config, @args);
        /^status$/    and return $self->_status($app, $config, @args);
        /^prepare$/   and return $self->_prepare($app, $config, @args);
        /^populate$/  and return $self->_populate($app, $config, @args);
        die $self->usage;
    }
}

# ---------------------------------------------------------------------------
# Build a DeploymentHandler with ignore_ddl => 1
# ---------------------------------------------------------------------------

sub _build_dh ($self, $app, $config) {
    my $native = $self->_build_native_schema($app, $config)
        or return undef;

    my $mig_dir = path($config->{migrations_dir});

    # Derive database type from DSN (e.g. dbi:SQLite:... -> SQLite, dbi:Pg:... -> Pg)
    my $c    = $app->build_controller;
    my $bdef = $c->backend_config($config->{backend});
    my ($driver) = $bdef->{dsn} =~ /^dbi:([^:]+):/i
        or die "Cannot parse DSN: $bdef->{dsn}\n";

    require DBIx::Class::DeploymentHandler;
    return DBIx::Class::DeploymentHandler->new(
        schema              => $native,
        script_directory    => $mig_dir->to_string,
        databases           => [$driver],
        sql_translator_args => { add_drop_table => 0 },
        ignore_ddl          => 1,
    );
}

# ---------------------------------------------------------------------------
# db bootstrap-schema -- create a minimal DBIx::Class::Schema class file
# ---------------------------------------------------------------------------

sub _bootstrap_schema ($self, $app, $config, @args) {
    my $class_name;
    my $backend_name;
    my $force;

    # Parse options
    for (my $i = 0; $i < @args; $i++) {
        if ($args[$i] eq '--class' && defined $args[$i + 1]) {
            $class_name = $args[$i + 1];
            $i++;
        }
        elsif ($args[$i] eq '--backend' && defined $args[$i + 1]) {
            $backend_name = $args[$i + 1];
            $i++;
        }
        elsif ($args[$i] eq '--force') {
            $force = 1;
        }
    }

    # Resolve backend name
    unless ($backend_name) {
        my $c = $app->build_controller;
        if ($c->has_helper('default_backend_name')) {
            $backend_name = $c->default_backend_name($config->{backend});
        }
        elsif ($config->{backend}) {
            $backend_name = $config->{backend};
        }
    }

    unless ($backend_name) {
        die "No backend specified. Use --backend <name> or configure one.\n";
    }

    # Check if DBIx::Async is loaded and schema_class already configured
    my $c = $app->build_controller;
    if ($c->has_helper('backend_config')) {
        my $bdef = eval { $c->backend_config($backend_name) };
        if ($bdef && $bdef->{schema_class}) {
            if ($class_name && $class_name ne $bdef->{schema_class}) {
                say "Note: backend '$backend_name' already has schema_class '"
                    . "$bdef->{schema_class}'. Generating '$class_name' anyway.";
            }
            # Use existing schema_class if no --class given
            $class_name //= $bdef->{schema_class};
        }
    }

    # Derive class name from moniker if not specified
    unless ($class_name) {
        my $moniker = $app->moniker // 'MyApp';
        $class_name = ucfirst($moniker) . '::Schema';
    }

    # Determine file path under lib/
    (my $class_path = "$class_name.pm") =~ s{::}{/}g;
    my $file = $app->home->child('lib', $class_path);

    # Check for existing file
    if (-f $file) {
        if (!$force) {
            die "Schema file already exists: $file\n"
                . "Use --force to overwrite.\n";
        }

        # --force: only overwrite files that were generated by this tool.
        # Refuse to touch a user-created schema class to avoid data loss.
        my $existing = $file->slurp;
        unless ($existing =~ /^# BOOTSTRAPPED BY Fondation::MigrationDBIx/m) {
            die "Schema file was NOT generated by db bootstrap-schema: $file\n"
                . "Refusing to overwrite user-created schema class.\n";
        }
    }

    # Create parent directories
    $file->dirname->make_path;

    # Write the minimal schema class
    my $content = <<"SCHEMA";
package $class_name;

# BOOTSTRAPPED BY Fondation::MigrationDBIx -- do not edit this marker.
# This file is managed by 'db bootstrap-schema'.  Removing or changing
# the marker above will prevent --force from overwriting it, protecting
# user-created schema classes from accidental data loss.

use base 'DBIx::Class::Schema';

# Increment this version when you change the schema.
# Run 'db prepare' after altering tables, then 'db upgrade' to apply.
our \$VERSION = '1';

# Auto-discovers Result classes under ${class_name}::Result::*
# Local classes take priority over plugin Result classes registered
# by the DBIx action (load_namespaces runs during connect(), after
# the action has registered plugin sources).
__PACKAGE__->load_namespaces;

1;
SCHEMA

    $file->spurt($content);

    say "Created $file";
    say "";

    # Show configuration instructions if schema_class is not yet configured
    if ($c->has_helper('backend_config')) {
        my $bdef = eval { $c->backend_config($backend_name) };
        if (!$bdef) {
            say "Backend '$backend_name' not found in DBIx::Async config.";
            say "Make sure Fondation::Model::DBIx::Async is configured with a";
            say "backend named '$backend_name'.";
            say "";
            say "  'Fondation::Model::DBIx::Async' => {";
            say "      backends => [";
            say "          $backend_name => {";
            say "              dsn          => 'dbi:SQLite:dbname=data/app.db',";
            say "              schema_class => '$class_name',";
            say "          },";
            say "      ],";
            say "  },";
        }
        elsif (!$bdef->{schema_class}) {
            say "Add this to your backend '$backend_name' config in myapp.conf:";
            say "";
            say "  schema_class => '$class_name',   # ← add this line";
            say "";
            say "Then run: myapp.pl db prepare";
        }
        else {
            say "Schema class '$class_name' is ready.";
            say "Run: myapp.pl db prepare";
        }
    }
    else {
        say "Add 'schema_class => '$class_name'' to your backend";
        say "'$backend_name' in Fondation::Model::DBIx::Async config.";
        say "Then run: myapp.pl db prepare";
    }
}

# ---------------------------------------------------------------------------
# db prepare -- generate SQL from schema + copy fixtures from plugins
# ---------------------------------------------------------------------------

sub _prepare ($self, $app, $config, @args) {
    my $yes       = grep { $_ eq '-y' } @args;
    my $auto_bump = grep { $_ eq '-a' } @args;

    my $mig_dir = path($config->{migrations_dir});
    my $fix_dir = $app->home->child('share', 'fixtures');

    # Detect schema drift (changes since last prepare)
    my $c     = $app->build_controller;
    my $drift = $c->has_helper('schema_drift')
        ? eval { $c->schema_drift } : undef;

    if ($drift && $drift->{has_drift} && !$auto_bump) {
        say "\nSchema version $drift->{version} has drifted since last prepare:";
        for my $name (sort keys %{$drift->{changes}}) {
            my $ch = $drift->{changes}{$name};
            if ($ch eq 'new') {
                say "  + $name (new table)";
            }
            elsif ($ch eq 'removed') {
                say "  - $name (removed)";
            }
            else {
                my @details;
                push @details, "+" . join(',+', @{$ch->{added}})
                    if @{$ch->{added}};
                push @details, "-" . join(',-', @{$ch->{removed}})
                    if @{$ch->{removed}};
                for my $col (sort keys %{$ch->{modified}}) {
                    my $mod = $ch->{modified}{$col};
                    my @attrs = sort keys %$mod;
                    push @details, "~$col(" . join(',', @attrs) . ")";
                }
                if ($ch->{primary_keys}) {
                    push @details, "~PK";
                }
                say "  ~ $name ("
                    . join('; ', @details) . ")" if @details;
            }
        }
        say "\nRun 'db prepare -a' to auto-bump the version and generate the";
        say "migration, or bump \$VERSION in your schema class manually.";
        return;
    }

    # Auto-bump schema version if requested
    if ($auto_bump && $drift && $drift->{has_drift}) {
        say "Schema drifted -- auto-bumping version...";
        $self->_bump_schema_version($app, $config);
    }

    # Check if target directories already have content
    my @existing;
    push @existing, 'migrations' if $self->_dir_has_content($mig_dir);
    push @existing, 'fixtures'   if $self->_dir_has_content($fix_dir);

    if (@existing && !$yes) {
        my $counts = '';
        $counts .= sprintf "  %-12s %d file(s)\n", 'migrations',
            $self->_file_count($mig_dir) if $self->_dir_has_content($mig_dir);
        $counts .= sprintf "  %-12s %d file(s)\n", 'fixtures',
            $self->_file_count($fix_dir) if $self->_dir_has_content($fix_dir);
        say "\nTarget directories already have content:";
        print $counts;
        say "";
        print "Overwrite existing files? [y/N] ";
        my $answer = <STDIN>;
        chomp $answer;
        exit(0) unless $answer =~ /^y(es)?$/i;
    }

    my $force = $yes || (@existing > 0);

    # Generate SQL from schema classes via DeploymentHandler
    my $dh = $self->_build_dh($app, $config);
    if ($dh) {
        # Remove existing generated dirs so DeploymentHandler regenerates cleanly --
        # skip this when auto-bumping (we're adding a version, not rebuilding)
        unless ($auto_bump) {
            $mig_dir->child('_source')->remove_tree if $force && -d $mig_dir->child('_source');
            $mig_dir->child('SQLite')->remove_tree  if $force && -d $mig_dir->child('SQLite');
        }

        $dh->prepare_install;
        say "Done.";

        # Save schema signature for future drift detection
        $self->_save_sig($app, $config, $dh);
    }

    # Copy fixture tree from all plugins to the versioned directory.
    # Fixtures live under share/fixtures/<schema_version>/ — the version
    # comes from the schema class $VERSION (reflected by DeploymentHandler).
    # This ensures db populate always loads fixtures for the current schema
    # version, even after a version bump via db prepare -a.
    my $version = $dh ? eval { $dh->schema_version } // '1' : '1';
    my $fix_version_dir = $fix_dir->child($version);
    my $fix_copied = $self->_copy_tree_from_plugins(
        $app, 'fixtures', $fix_version_dir, $force);
    say sprintf "Fixtures:   %d file(s) copied to v%s.", $fix_copied, $version
        if $fix_copied;
}

# ---------------------------------------------------------------------------
# Copy a share subdirectory tree from all plugins to the app
# ---------------------------------------------------------------------------

sub _copy_tree_from_plugins ($self, $app, $subdir, $target_dir, $force) {
    my $manager = $app->manager;
    my $copied  = 0;

    # Clean target if forcing overwrite
    $target_dir->remove_tree({ keep_root => 1 }) if $force && -d $target_dir;
    $target_dir->make_path unless -d $target_dir;

    for my $long (sort keys %{$manager->registry}) {
        my $entry = $manager->registry->{$long};
        my $share = $entry->{share_dir} or next;
        my $src_root = $share->child($subdir);
        next unless -d $src_root;

        my @all_files = @{ $src_root->list_tree({ hidden => 1 }) // [] };
        for my $src (@all_files) {
            next unless -f $src;

            my $rel_path = $src->to_rel($src_root);

            # Strip the plugin's fixture version prefix (e.g. "1/" or "1\")
            # so that fixtures land in the target version directory
            # determined by the current schema version.
            $rel_path =~ s{^[^/\\]+[/\\]}{};
            my $target = $target_dir->child($rel_path);

            next if -e $target && !$force;

            $target->dirname->make_path unless -d $target->dirname;
            eval { $src->copy_to($target); 1 }
                or do {
                    warn "  Failed to copy $rel_path: $@\n";
                    next;
                };
            $copied++;
        }
    }

    return $copied;
}

# ---------------------------------------------------------------------------
# db install -- run DeploymentHandler install
# ---------------------------------------------------------------------------

sub _install ($self, $app, $config, @args) {
    my $dh = $self->_build_dh($app, $config)
        or return;

    my $mig_dir = path($config->{migrations_dir});

    unless (-d $mig_dir) {
        say "No migrations directory: $mig_dir";
        say "Run 'db prepare' first to generate migration files from schema.";
        return;
    }

    my $schema_v = $dh->schema_version;
    my $db_v     = $dh->version_storage_is_installed
        ? $dh->database_version : 0;

    if ($db_v && $db_v >= $schema_v) {
        say "Already at version $db_v (schema: $schema_v). Nothing to migrate.";
        return;
    }

    say "Installing schema (version $schema_v)...";
    $dh->install;
    my $active = eval { $dh->database_version } // $schema_v;
    say "Done. Active version: $active";
}

# ---------------------------------------------------------------------------
# db upgrade -- run pending upgrades
# ---------------------------------------------------------------------------

sub _upgrade ($self, $app, $config, @args) {
    my $dh = $self->_build_dh($app, $config)
        or return;

    my $db_v     = $dh->version_storage_is_installed
        ? $dh->database_version : 0;
    my $schema_v = $dh->schema_version;

    return say "Already at latest version $db_v." if $db_v >= $schema_v;

    say "Upgrading from version $db_v to " . ($db_v + 1) . "...";
    $dh->upgrade;
    say "Done. Active version: " . $dh->database_version;
}

# ---------------------------------------------------------------------------
# db downgrade -- rollback one version
# ---------------------------------------------------------------------------

sub _downgrade ($self, $app, $config, @args) {
    my $dh = $self->_build_dh($app, $config)
        or return;

    my $db_v = $dh->version_storage_is_installed
        ? $dh->database_version : 0;
    die "No version installed. Nothing to downgrade.\n" unless $db_v;

    my $target_v = $db_v - 1;

    # Temporarily set the schema $VERSION one lower so DeploymentHandler
    # sees schema_version < database_version and triggers the downgrade.
    my $c = $app->build_controller;
    my $schema_class = $c->has_helper('schema_class')
        ? $c->schema_class : undef;
    if ($schema_class) {
        no strict 'refs';
        ${"${schema_class}::VERSION"} = $target_v;
    }

    say "Downgrading from version $db_v to $target_v...";
    $dh->downgrade;
    say "Done. Active version: " . $dh->database_version;

    # Restore the original version
    if ($schema_class) {
        no strict 'refs';
        ${"${schema_class}::VERSION"} = $db_v;
    }
}

# ---------------------------------------------------------------------------
# db status -- show current vs latest migration version
# ---------------------------------------------------------------------------

sub _status ($self, $app, $config, @args) {
    my $dh = $self->_build_dh($app, $config)
        or return;

    my $schema_v = $dh->schema_version // 'unknown';
    my $db_v     = $dh->version_storage_is_installed
        ? $dh->database_version : 'none';

    say "Schema version : $schema_v";
    say "Active version : $db_v";
    say "Status         : "
        . ($dh->version_storage_is_installed && $db_v >= $schema_v
            ? "up to date" : "migrations pending");
}

# ---------------------------------------------------------------------------
# db populate -- load DBIx fixtures
# ---------------------------------------------------------------------------

sub _populate ($self, $app, $config, @args) {
    my $set_filter;  # undef = all sets
    my $force;

    # Parse options
    for (my $i = 0; $i < @args; $i++) {
        if ($args[$i] eq '--set' && defined $args[$i + 1]) {
            $set_filter = $args[$i + 1];
            $i++;
            next;
        }
        if ($args[$i] eq '--force') {
            $force = 1;
        }
    }

    my $dh = $self->_build_dh($app, $config)
        or return;

    my $set_version = $dh->version_storage_is_installed
        ? $dh->database_version : 0;
    die "No database version. Run 'db install' or 'db upgrade' first.\n"
        unless $set_version;

    my $conf_dir = $app->home->child('share', 'fixtures', $set_version, 'conf');

    unless (-d $conf_dir) {
        say "Fixture config directory not found: $conf_dir";
        return;
    }

    # Discover available set names from conf/*.json
    my @all_sets;
    for my $file (sort $conf_dir->list({ file => 1 })->each) {
        next unless $file->basename =~ /\.json$/i;
        (my $set_name = $file->basename) =~ s/\.json$//i;
        push @all_sets, $set_name;
    }

    unless (@all_sets) {
        say "No fixture sets found in $conf_dir";
        return;
    }

    # Filter by --set or use all
    my @sets = $set_filter
        ? grep { $_ eq $set_filter } @all_sets
        : @all_sets;

    unless (@sets) {
        die "Fixture set '$set_filter' not found. Available: "
            . join(', ', @all_sets) . "\n";
    }

    # Ensure the fixtures_loaded tracking table exists
    my $native = $dh->schema;
    my $storage = $native->storage;
    $storage->ensure_connected;
    $storage->dbh_do(sub {
        my ($storage, $dbh) = @_;
        $dbh->do(<<'SQL');
            CREATE TABLE IF NOT EXISTS fixtures_loaded (
                set_name  VARCHAR(255) NOT NULL PRIMARY KEY,
                loaded_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
            )
SQL
    });

    # Check which sets have already been loaded
    my %loaded;
    {
        my ($sth, @rows);
        $storage->dbh_do(sub {
            my ($storage, $dbh) = @_;
            $sth = $dbh->prepare('SELECT set_name FROM fixtures_loaded');
            $sth->execute;
            @rows = @{$sth->fetchall_arrayref // []};
        });
        %loaded = map { $_->[0] => 1 } @rows;
    }

    # Filter out already-loaded sets (unless --force)
    if (!$force) {
        my @to_load;
        my @skipped;
        for my $set (@sets) {
            if ($loaded{$set}) {
                push @skipped, $set;
            } else {
                push @to_load, $set;
            }
        }
        say "Skipping already-loaded set(s): " . join(', ', @skipped)
            if @skipped;
        say "  Use --force to reload them." if @skipped;
        @sets = @to_load;
    }

    unless (@sets) {
        say "All sets already loaded. Nothing to do.";
        return;
    }

    require DBIx::Class::Fixtures;
    my $fixtures = DBIx::Class::Fixtures->new({
        config_dir => $conf_dir->to_string,
    });

    say "Populating set(s): " . join(', ', @sets);
    for my $set (@sets) {
        my $set_dir = $app->home->child(
            'share', 'fixtures', $set_version, $set)->to_string;
        eval {
            $fixtures->populate({
                no_deploy => 1,
                directory => $set_dir,
                schema    => $native,
            });
            1;
        } or die "Failed to populate set '$set': $@";

        # Record that this set has been loaded
        $storage->dbh_do(sub {
            my ($storage, $dbh) = @_;
            $dbh->do(
                'INSERT OR REPLACE INTO fixtures_loaded (set_name) VALUES (?)',
                undef, $set);
        });
    }
    say "Populate complete.";
}

# ---------------------------------------------------------------------------
# Build a native DBIx::Class::Schema from backend config
# ---------------------------------------------------------------------------

sub _build_native_schema ($self, $app, $config) {
    # Resolve backend: explicit config -> DBIx::Async default -> first backend -> undef
    my $c = $app->build_controller;
    my $backend_name;
    if ($c->has_helper('default_backend_name')) {
        $backend_name = $c->default_backend_name($config->{backend});
    } else {
        $backend_name = $config->{backend};
    }

    unless ($backend_name) {
        say "No backend configured. Set 'backend' in MigrationDBIx config"
            . " or 'default_backend' in Fondation::Model::DBIx::Async.";
        return undef;
    }

    my $bdef;
    unless ($app->has_helper('backend_config')) {
        say "Fondation::Model::DBIx::Async is not loaded. No backend_config helper.";
        return undef;
    }

    $bdef = eval { $c->backend_config($backend_name) };
    unless ($bdef) {
        say "Backend '$backend_name' not found.";
        return undef;
    }

    my $schema_class = $bdef->{schema_class}
        or die "No schema_class configured for backend '$backend_name'\n";

    eval "require $schema_class; 1"
        or die "Cannot load schema class $schema_class: $@\n"
            . "Run 'db bootstrap-schema' to create the file.\n";

    # Ensure parent directory exists for file-based DSNs (SQLite)
    if ($bdef->{dsn} =~ /^dbi:SQLite:(?:dbname=)?(.+)$/i) {
        my $db_path = $1;
        my $dir = Mojo::File->new($db_path)->dirname;
        $dir->make_path unless -d $dir;
    }

    my $native = $schema_class->connect(
        $bdef->{dsn},
        $bdef->{user}      // '',
        $bdef->{pass}      // '',
        $bdef->{dbi_attrs} // {},
    );

    return $native;
}

# ---------------------------------------------------------------------------
# Helpers for directory content detection
# ---------------------------------------------------------------------------

sub _dir_has_content ($self, $dir) {
    return 0 unless -d $dir;
    my @files = grep { -f $_ } @{ $dir->list_tree({ hidden => 1 }) // [] };
    return scalar @files > 0;
}

sub _file_count ($self, $dir) {
    return 0 unless -d $dir;
    return scalar grep { -f $_ } @{ $dir->list_tree({ hidden => 1 }) // [] };
}

# ---------------------------------------------------------------------------
# Save schema signature for future drift detection
# ---------------------------------------------------------------------------

sub _save_sig ($self, $app, $config, $dh) {
    my $c = $app->build_controller;
    my $live_sig = $c->schema_sig($dh->schema);

    my $version = $dh->schema_version
        or die "Cannot determine schema version after prepare\n";

    my $sig = {
        version => $version,
        sources => $live_sig,
    };

    my $sig_file = $config->{sig_file}
        or return;

    path($sig_file)->dirname->make_path;
    path($sig_file)->spurt(encode_json($sig));
}

# ---------------------------------------------------------------------------
# Auto-bump the schema version in the class file
# ---------------------------------------------------------------------------

sub _bump_schema_version ($self, $app, $config) {
    my $c = $app->build_controller;

    my $schema_class;
    if ($c->has_helper('schema_class')) {
        $schema_class = $c->schema_class;
    }

    unless ($schema_class) {
        say "Cannot auto-bump: no schema_class configured.";
        return;
    }

    (my $class_path = "$schema_class.pm") =~ s{::}{/}g;
    my $file = $app->home->child('lib', $class_path);

    unless (-f $file) {
        say "Cannot auto-bump: schema file not found ($file).";
        return;
    }

    my $content = $file->slurp;
    unless ($content =~ /^our\s+\$VERSION\s*=\s*['"]?(\d+)['"]?\s*;/m) {
        say "Cannot auto-bump: no \$VERSION found in $schema_class.";
        return;
    }

    my $old_version = $1;
    my $new_version = $old_version + 1;

    $content =~ s/^(our\s+\$VERSION\s*=\s*['"]?)$old_version(['"]?\s*;)/${1}${new_version}${2}/m
        or do {
            say "Cannot auto-bump: failed to replace \$VERSION.";
            return;
        };

    $file->spurt($content);
    say "Bumped \$VERSION from $old_version to $new_version in $file";

    # Update the in-memory $VERSION so the next _build_dh sees it.
    # Direct assignment avoids reloading the class (which would lose
    # all register_source calls from Action::DBIx).
    {
        no strict 'refs';
        ${"${schema_class}::VERSION"} = $new_version;
    }
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Mojolicious::Plugin::Fondation::MigrationDBIx::Command::db - Database migration and fixture commands for DBIx::Class backends

=head1 VERSION

version 0.03

=head1 SYNOPSIS

  $ myapp.pl db bootstrap-schema
  $ myapp.pl db prepare
  $ myapp.pl db install
  $ myapp.pl db status
  $ myapp.pl db populate --set 1

=head1 DESCRIPTION

Command-line interface for managing database migrations and fixtures
for DBIx::Class backends managed by L<Fondation::Model::DBIx::Async>.

Migrations use L<DBIx::Class::DeploymentHandler> directly with C<ignore_ddl = 1>.
Upgrade and downgrade SQL are generated on-the-fly from C<_source/> YAML files --
no C<db dump> step is needed.

=head1 NAME

Mojolicious::Plugin::Fondation::MigrationDBIx::Command::db - Database migration and fixture commands

=head1 COMMANDS

=head2 db bootstrap-schema [--class ClassName] [--backend name] [--force]

Creates a minimal L<DBIx::Class::Schema> class file under C<lib/>. Use this
when you have DBIx backends configured but no C<schema_class> yet, or when
C<schema_class> is configured but the file does not exist. After creating
the file, add C<schema_class> to your backend config (if not already set)
and run C<db prepare> to generate migration files.

The generated class uses C<load_namespaces> to auto-discover any C<Result>
classes under the application's C<Schema::Result::*> namespace. Result
classes from Fondation plugins are registered separately by the C<DBIx>
action before workers fork -- both mechanisms coexist transparently.

If C<schema_class> is already configured in your backend, C<bootstrap-schema>
uses that class name automatically (no C<--class> needed).

=head3 Options

=over

=item C<--class ClassName>

Full class name for the schema. Defaults to C<< <Moniker>::Schema >>
(e.g. C<MyApp::Schema> when the application moniker is C<my_app>), or to
the already-configured C<schema_class> if the backend defines one.

=item C<--backend name>

Backend name to reference in the post-creation instructions. When omitted,
resolves via C<default_backend_name> (same cascade as other C<db> commands:
explicit C<Fondation::MigrationDBIx> C<backend> config -> DBIx::Async
C<default_backend> -> first backend).

=item C<--force>

Overwrite the schema file if it already exists.

=back

=head3 Local vs plugin Result priority

When both the application and a plugin define a C<Schema::Result::*> class
for the same table, the application's class wins: C<load_namespaces> runs
during C<connect()>, I<after> the C<DBIx> action has registered plugin sources.
The later registration overwrites the earlier one.

This means you can extend or replace a plugin's Result class by defining
your own under C<< $AppSchema::Result::* >> with the same
C<< __PACKAGE__->table(...) >>.

=head2 db prepare [-y] [-a]

Generates SQL migration files from the schema classes and copies fixture
directories from all loaded plugins. Use C<-y> to skip the overwrite prompt.

Before generating, compares the live schema signature against the
C<.schema-sig.json> file saved after the last prepare. If the schema has
drifted -- for example because a plugin Result class changed after a
C<cpanm> upgrade -- the changed sources are reported and the command exits.

Use C<-a> to auto-bump the schema C<$VERSION> and generate the migration.
The version is incremented in the class file and in memory; previous
migration versions are preserved.

=head1 AUTHOR

Daniel Brosseau <dab@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by Daniel Brosseau.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
