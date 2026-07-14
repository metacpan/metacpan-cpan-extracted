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

# ==========================================================================
# 1. Status before install
# ==========================================================================
{
    my $app = build_app;
    $app->commands->run('db', 'prepare', '-y');

    my $out = '';
    {
        open my $fh, '>', \$out;
        local *STDOUT = $fh;
        local *STDERR = $fh;
        eval { $app->commands->run('db', 'status'); 1 };
    }

    like($out, qr/Active version : none/, 'no version before install')
        or diag "output: $out";
    like($out, qr/migrations pending/, 'pending before install')
        or diag "output: $out";
}

# ==========================================================================
# 2. Status after install
# ==========================================================================
{
    my $app = build_app;
    $app->commands->run('db', 'prepare', '-y');
    $app->commands->run('db', 'install');

    my $out = '';
    {
        open my $fh, '>', \$out;
        local *STDOUT = $fh;
        local *STDERR = $fh;
        eval { $app->commands->run('db', 'status'); 1 };
    }

    like($out, qr/Active version : 1/, 'version 1 after install')
        or diag "output: $out";
    like($out, qr/up to date/, 'up to date after install')
        or diag "output: $out";
}

done_testing;
