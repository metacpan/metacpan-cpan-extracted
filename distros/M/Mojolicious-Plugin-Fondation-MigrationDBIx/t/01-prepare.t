use strict;
use warnings;
use Test::More;
use Mojolicious;
use Mojo::File 'path';
use File::Temp 'tempdir';
use FindBin;
use lib "$FindBin::Bin/../lib";
use lib "$FindBin::Bin/lib";

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

    return $app;
}

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

# ==========================================================================
# 1. Copies migrations
# ==========================================================================
{
    my $app  = build_app;
    my $out  = capture_run($app, 'db', 'prepare', '-y');

    my $mig_dir = $app->home->child('share', 'migrations');
    ok(-d $mig_dir, 'migrations directory created')
        or diag "output: $out";

    my @files = sort grep { -f $_ } @{ $mig_dir->list_tree({ hidden => 1 }) // [] };
    ok(scalar @files > 0, 'migration files copied')
        or diag "output: $out";
}

# ==========================================================================
# 2. Copies fixtures
# ==========================================================================
{
    my $app = build_app;
    my $out = capture_run($app, 'db', 'prepare', '-y');

    my $fix_dir = $app->home->child('share', 'fixtures');
    ok(-d $fix_dir, 'fixtures directory created')
        or diag "output: $out";

    my @files = grep { -f $_ } @{ $fix_dir->list_tree({ hidden => 1 }) // [] };
    ok(scalar @files > 0, 'fixture files copied')
        or diag "output: $out";
}

# ==========================================================================
# 3. Reports preparation summary
# ==========================================================================
{
    my $app = build_app;
    my $out = capture_run($app, 'db', 'prepare', '-y');

    like($out, qr/Done/, 'reports preparation done');
    like($out, qr/Fixtures:\s+\d+ file\(s\)/, 'reports fixture count');
}

# ==========================================================================
# 4. First run: no prompt, copies everything
# ==========================================================================
{
    my $app = build_app;
    my $out = capture_run($app, 'db', 'prepare');

    unlike($out, qr/Overwrite/, 'no overwrite prompt on first run');
}

done_testing;
