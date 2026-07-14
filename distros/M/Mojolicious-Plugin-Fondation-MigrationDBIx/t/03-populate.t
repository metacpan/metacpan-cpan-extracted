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

    return ($app, $dbfile);
}

# ==========================================================================
# 1. Populate inserts fixture data
# ==========================================================================
{
    my ($app, $dbfile) = build_app;
    $app->commands->run('db', 'prepare', '-y');

    # Fixtures should be in the schema version directory (v1)
    my $fix_v1 = $app->home->child('share', 'fixtures', '1');
    ok(-d $fix_v1, 'fixtures in v1 directory');
    ok(-f $fix_v1->child('conf', 'foo.json'), 'foo fixture config in v1');

    $app->commands->run('db', 'install');

    my $out = '';
    {
        open my $fh, '>', \$out;
        local *STDOUT = $fh;
        local *STDERR = $fh;
        eval { $app->commands->run('db', 'populate'); 1 };
    }

    like($out, qr/Populate complete/, 'populate completes')
        or diag "output: $out";

    # Verify data via raw DBI
    require TestSchema;
    my $native = TestSchema->connect("dbi:SQLite:dbname=$dbfile");
    my $rs = $native->resultset('Foo');
    my @rows = $rs->all;
    is(scalar @rows, 1, 'one row inserted');
    is($rows[0]->name, 'alpha', 'row has correct name');
}

# ==========================================================================
# 2. Populate with --set filter
# ==========================================================================
{
    my ($app, $dbfile) = build_app;
    $app->commands->run('db', 'prepare', '-y');

    # Fixtures should be in the schema version directory (v1)
    my $fix_v1 = $app->home->child('share', 'fixtures', '1');
    ok(-d $fix_v1, 'fixtures in v1 directory');
    ok(-f $fix_v1->child('conf', 'foo.json'), 'foo fixture config in v1');

    $app->commands->run('db', 'install');

    my $out = '';
    {
        open my $fh, '>', \$out;
        local *STDOUT = $fh;
        local *STDERR = $fh;
        eval { $app->commands->run('db', 'populate', '--set', 'foo'); 1 };
    }

    like($out, qr/Populating set\(s\): foo/, 'filters to foo set')
        or diag "output: $out";
    like($out, qr/Populate complete/, 'populate with --set works');
}

done_testing;
