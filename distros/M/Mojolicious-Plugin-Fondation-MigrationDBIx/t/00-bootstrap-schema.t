use strict;
use warnings;
use Test::More;
use Mojolicious;
use Mojo::File 'path';
use File::Temp 'tempdir';
use FindBin;
use lib "$FindBin::Bin/../lib";
use lib "$FindBin::Bin/lib";

# capture_run captures STDOUT+STDERR, but the command runner calls exit() on
# failure.  Use this only for commands expected to succeed.
sub capture_run {
    my ($app, @args) = @_;
    my $buf;
    open my $fh, '>', \$buf;
    local *STDOUT = $fh;
    local *STDERR = $fh;
    $app->commands->run(@args);
    close $fh;
    return $buf;
}

# Build a Fondation app with DBIx::Async + MigrationDBIx.
# Pass schema_class => undef to omit it from the backend config.
sub build_app {
    my (%opts) = @_;
    my $tmpdir = $opts{tmpdir} // tempdir(CLEANUP => 1);
    my $schema_class = $opts{schema_class};

    my $app = Mojolicious->new;
    $app->moniker('TestApp');
    $app->log->level('fatal');
    $app->home(path($tmpdir));

    my $backend_cfg = {
        dsn => "dbi:SQLite:dbname=$tmpdir/test.db",
    };
    $backend_cfg->{schema_class} = $schema_class if defined $schema_class;

    $app->plugin('Fondation' => {
        dependencies => [
            { 'Fondation::Model::DBIx::Async' => {
                backends => [ main => $backend_cfg ],
            }},
            { 'Fondation::MigrationDBIx' => {} },
        ],
    });

    return $app;
}

# ==========================================================================
# 1. Bootstrap without schema_class → creates file, shows config hint
# ==========================================================================
{
    my $tmpdir = tempdir(CLEANUP => 1);
    my $app = build_app(tmpdir => $tmpdir, schema_class => undef);
    my $out = capture_run($app, 'db', 'bootstrap-schema');

    my $file = path($tmpdir, 'lib', 'TestApp', 'Schema.pm');
    ok(-f $file, 'schema file created') or diag "output: $out";

    my $content = $file->slurp;
    like($content, qr/package TestApp::Schema/,    'correct package name');
    like($content, qr/use base 'DBIx::Class::Schema'/, 'extends DBIC::Schema');
    like($content, qr/our \$VERSION = '1'/,        'has version');
    like($content, qr/__PACKAGE__->load_namespaces/, 'has load_namespaces');

    like($out, qr/Created/,          'reports file creation');
    like($out, qr/schema_class.*add this line/i, 'shows config hint');
}

# ==========================================================================
# 2. Bootstrap when schema_class IS configured but file missing → uses it
# ==========================================================================
{
    my $tmpdir = tempdir(CLEANUP => 1);
    my $app = build_app(tmpdir => $tmpdir, schema_class => 'MySchema');
    my $out = capture_run($app, 'db', 'bootstrap-schema');

    my $file = path($tmpdir, 'lib', 'MySchema.pm');
    ok(-f $file, 'file created from configured class name')
        or diag "output: $out";

    my $content = $file->slurp;
    like($content, qr/package MySchema/,  'uses configured class name');
    like($out, qr/MySchema.*ready/i,      'reports using configured name');
}

# ==========================================================================
# 3. --class overrides the configured schema_class
# ==========================================================================
{
    my $tmpdir = tempdir(CLEANUP => 1);
    my $app = build_app(tmpdir => $tmpdir, schema_class => 'MySchema');
    my $out = capture_run($app, 'db', 'bootstrap-schema',
        '--class', 'OtherSchema');

    my $orig = path($tmpdir, 'lib', 'MySchema.pm');
    my $file = path($tmpdir, 'lib', 'OtherSchema.pm');
    ok(-f $file, 'file created with --class name') or diag "output: $out";
    ok(!-f $orig, 'original name not created');
    like($out, qr/Note.*already has schema_class.*MySchema.*Generating.*OtherSchema/i,
        'warns about class mismatch');
}

# ==========================================================================
# 4. File exists, no --force → dies
# ==========================================================================
# mojolicious::Commands::run() calls exit() on failure, so we can't use
# capture_run here.  Call the internal builder directly.
{
    my $tmpdir = tempdir(CLEANUP => 1);
    my $app = build_app(tmpdir => $tmpdir, schema_class => undef);

    # Pre-create the file
    path($tmpdir, 'lib', 'TestApp')->make_path;
    path($tmpdir, 'lib', 'TestApp', 'Schema.pm')->spurt('existing');

    require Mojolicious::Plugin::Fondation::MigrationDBIx::Command::db;
    my $cmd = Mojolicious::Plugin::Fondation::MigrationDBIx::Command::db
        ->new(app => $app);
    my $config = $app->defaults->{'migration_dbix.config'};

    my $died = !eval {
        $cmd->_bootstrap_schema($app, $config);
        1;
    };
    ok($died, 'dies when file already exists');
    like($@, qr/already exists/s,      'mentions file exists');
    like($@, qr/Use --force to overwrite/, 'suggests --force');
}

# ==========================================================================
# 5. --force overwrites existing file
# ==========================================================================
{
    my $tmpdir = tempdir(CLEANUP => 1);
    my $app = build_app(tmpdir => $tmpdir, schema_class => undef);

    path($tmpdir, 'lib', 'TestApp')->make_path;
    path($tmpdir, 'lib', 'TestApp', 'Schema.pm')->spurt('existing');

    my $out     = capture_run($app, 'db', 'bootstrap-schema', '--force');
    my $content = path($tmpdir, 'lib', 'TestApp', 'Schema.pm')->slurp;

    like($content, qr/load_namespaces/, 'file overwritten with schema content');
    like($out,     qr/Created/,         'reports creation after --force');
}

# ==========================================================================
# 6. No backend resolvable → dies with helpful message
# ==========================================================================
# Same as test 4: the command runner would exit(), so call directly.
{
    my $tmpdir = tempdir(CLEANUP => 1);
    my $app = Mojolicious->new;
    $app->moniker('TestApp');
    $app->log->level('fatal');
    $app->home(path($tmpdir));

    $app->plugin('Fondation' => {
        dependencies => [
            { 'Fondation::Model::DBIx::Async' => { backends => [] } },
            { 'Fondation::MigrationDBIx' => {} },
        ],
    });

    require Mojolicious::Plugin::Fondation::MigrationDBIx::Command::db;
    my $cmd = Mojolicious::Plugin::Fondation::MigrationDBIx::Command::db
        ->new(app => $app);
    my $config = $app->defaults->{'migration_dbix.config'};

    my $died = !eval {
        $cmd->_bootstrap_schema($app, $config);
        1;
    };
    ok($died, 'dies when no backend resolvable');
    like($@, qr/No backend specified/i, 'helpful error message');
}

# ==========================================================================
# 7. Prepare after bootstrap → schema class loads successfully
# ==========================================================================
{
    my $tmpdir = tempdir(CLEANUP => 1);
    my $app = build_app(tmpdir => $tmpdir, schema_class => 'MySchema');

    # Bootstrap the schema
    capture_run($app, 'db', 'bootstrap-schema');

    # add tempdir lib/ to @INC so 'require MySchema' can find the bootstrapped file
    unshift @INC, "$tmpdir/lib";

    # Now prepare should work -- the schema class exists
    my $out = capture_run($app, 'db', 'prepare', '-y');
    like($out, qr/Done/, 'db prepare succeeds after bootstrap');
}

done_testing;
