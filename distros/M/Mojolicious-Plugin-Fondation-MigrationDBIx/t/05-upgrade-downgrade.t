use strict;
use warnings;
use Test::More;
use Mojolicious;
use Mojo::File 'path';
use File::Temp 'tempdir';
use FindBin;
use lib "$FindBin::Bin/../lib";
use lib "$FindBin::Bin/lib";
use TestSchemaV2;   # preload v2 schema for upgrade/downgrade tests
use TestSchema;

my $SHARE_DIR = path($FindBin::Bin, 'lib', 'Mojolicious', 'Plugin',
    'Fondation', 'TestDBIx', 'share')->to_string;

sub build_app {
    my $tmpdir = tempdir(CLEANUP => 1);
    my $dbfile = "$tmpdir/test.db";

    my $app = Mojolicious->new;
    $app->moniker('TestApp');
    $app->log->level('fatal');
    $app->home(path($tmpdir));

    $app->plugin('Fondation' => {
        dependencies => [
            { 'Fondation::Model::DBIx::Async' => {
                backends => [
                    test => {
                        dsn          => "dbi:SQLite:dbname=$dbfile",
                        schema_class => 'TestSchema',
                        workers      => 1,
                    },
                ],
                models => {
                    foo => { source => 'Foo', backend => 'test' },
                },
            }},
            { 'Fondation::TestDBIx' => {
                share_dir => $SHARE_DIR,
            }},
            { 'Fondation::MigrationDBIx' => { backend => 'test' } },
        ],
    });

    return ($app, $dbfile);
}

sub build_dh {
    my ($dbfile, $mig_dir, $schema_class) = @_;

    eval "require $schema_class" or die $@;

    my $native = $schema_class->connect("dbi:SQLite:dbname=$dbfile");
    require DBIx::Class::DeploymentHandler;
    return DBIx::Class::DeploymentHandler->new(
        schema           => $native,
        script_directory => $mig_dir->to_string,
        databases        => ['SQLite'],
        ignore_ddl       => 1,
    );
}

# ==========================================================================
# 1. Upgrade at latest: reports already up to date
# ==========================================================================
{
    my ($app) = build_app;
    $app->commands->run('db', 'prepare', '-y');
    $app->commands->run('db', 'install');

    my $out = '';
    {
        open my $fh, '>', \$out;
        local *STDOUT = $fh;
        local *STDERR = $fh;
        eval { $app->commands->run('db', 'upgrade'); 1 };
    }

    like($out, qr/Already at latest/, 'upgrade at latest says already there')
        or diag "output: $out";
}

# ==========================================================================
# 2. Upgrade v1→v2 then downgrade v2→v1 (ignore_ddl: SQL from YAML diffs)
# ==========================================================================
{
    my ($app, $dbfile) = build_app;
    $app->commands->run('db', 'prepare', '-y');
    $app->commands->run('db', 'install');

    my $mig_dir = $app->home->child('share', 'migrations');

    # Prepare v2 schema and upgrade
    my $dh_v2 = build_dh($dbfile, $mig_dir, 'TestSchemaV2');
    $dh_v2->prepare_install;

    is($dh_v2->database_version, 1, 'database at version 1 before upgrade');
    is($dh_v2->schema_version, 2, 'schema version is 2');

    $dh_v2->upgrade;
    is($dh_v2->database_version, 2, 'database version is 2 after upgrade');

    # Downgrade back to v1: use v1 handler so schema_version < database_version
    my $dh_v1 = build_dh($dbfile, $mig_dir, 'TestSchema');
    $dh_v1->downgrade;
    is($dh_v1->database_version, 1, 'database version is 1 after downgrade');
}

# ==========================================================================
# 3. Re-upgrade v1→v2: verify new column exists
# ==========================================================================
{
    my ($app, $dbfile) = build_app;
    $app->commands->run('db', 'prepare', '-y');
    $app->commands->run('db', 'install');

    my $mig_dir = $app->home->child('share', 'migrations');

    my $dh_v2 = build_dh($dbfile, $mig_dir, 'TestSchemaV2');
    $dh_v2->prepare_install;
    $dh_v2->upgrade;
    # Verify description column exists in the actual database
    require TestSchema;
    my $native = TestSchema->connect("dbi:SQLite:dbname=$dbfile");
    my $dbh = $native->storage->dbh;
    my $sth = $dbh->prepare('PRAGMA table_info(foos)');
    $sth->execute;
    my @col_names;
    while (my $row = $sth->fetchrow_hashref) {
        push @col_names, $row->{name};
    }
    ok((grep { $_ eq 'description' } @col_names), 'description column exists after upgrade');
}

done_testing;
