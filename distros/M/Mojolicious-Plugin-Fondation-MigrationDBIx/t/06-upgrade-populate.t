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

my $SHARE2_DIR = path($FindBin::Bin, 'lib', 'Mojolicious', 'Plugin',
    'Fondation', 'TestDBIx2', 'share')->to_string;

# ==========================================================================
# Shared tempdir and database file across both phases
# ==========================================================================
my $tmpdir = tempdir(CLEANUP => 1);
my $dbfile = "$tmpdir/test.db";

# Dynamically create TestSchema so we can mutate $VERSION + register sources
my $lib_dir = path($tmpdir, 'lib');
$lib_dir->make_path;

$lib_dir->child('TestSchema.pm')->spurt(<<"SCHEMA");
package TestSchema;
use base 'DBIx::Class::Schema';
our \$VERSION = '1';
1;
SCHEMA

$lib_dir->child('TestSchema', 'Result')->make_path;
$lib_dir->child('TestSchema', 'Result', 'Foo.pm')->spurt(<<"FOO");
package TestSchema::Result::Foo;
use base 'DBIx::Class::Core';
__PACKAGE__->table('foos');
__PACKAGE__->add_columns(
    id   => { data_type => 'integer', is_auto_increment => 1, is_nullable => 0 },
    name => { data_type => 'varchar', is_nullable => 0, size => 100 },
);
__PACKAGE__->set_primary_key('id');
1;
FOO

unshift @INC, "$tmpdir/lib";

# ==========================================================================
# Phase 1: v1 — prepare + install + populate (single plugin)
# ==========================================================================
{
    my $app = Mojolicious->new;
    $app->moniker('TestApp');
    $app->log->level('fatal');
    $app->home(path($tmpdir));

    require TestSchema;
    require TestSchema::Result::Foo;

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

    # Register the source so DeploymentHandler sees it
    TestSchema->register_source(
        'Foo', TestSchema::Result::Foo->result_source_instance);

    $app->commands->run('db', 'prepare', '-y');
    $app->commands->run('db', 'install');

    my $out = '';
    {
        open my $fh, '>', \$out;
        local *STDOUT = $fh;
        local *STDERR = $fh;
        eval { $app->commands->run('db', 'populate'); 1 };
    }
    like($out, qr/Populate complete/, 'v1 populate completes')
        or diag "v1 populate: $out";

    # Verify foos has data
    my $native = TestSchema->connect("dbi:SQLite:dbname=$dbfile");
    my @foos = $native->resultset('Foo')->all;
    is(scalar @foos, 1, 'foos has data after v1 populate');
    is($foos[0]->name, 'alpha', 'foos row has correct name');
}

# ==========================================================================
# Phase 2: v2 — add 'bars' Result + second plugin → prepare -a → upgrade →
#           populate (new fixtures only) → verify both tables
# ==========================================================================

# Create the new Result class for the second table
$lib_dir->child('TestSchema', 'Result', 'Bar.pm')->spurt(<<"BAR");
package TestSchema::Result::Bar;
use base 'DBIx::Class::Core';
__PACKAGE__->table('bars');
__PACKAGE__->add_columns(
    id   => { data_type => 'integer', is_auto_increment => 1, is_nullable => 0 },
    name => { data_type => 'varchar', is_nullable => 0, size => 100 },
);
__PACKAGE__->set_primary_key('id');
1;
BAR

require TestSchema::Result::Bar;

# Bump $VERSION in-memory so DeploymentHandler sees v2
{
    no strict 'refs';
    ${'TestSchema::VERSION'} = 2;
}

{
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
                    bar => { source => 'Bar', backend => 'test' },
                },
            }},
            { 'Fondation::TestDBIx' => {
                share_dir => $SHARE_DIR,
            }},
            { 'Fondation::TestDBIx2' => {
                share_dir => $SHARE2_DIR,
            }},
            { 'Fondation::MigrationDBIx' => { backend => 'test' } },
        ],
    });

    TestSchema->register_source(
        'Foo', TestSchema::Result::Foo->result_source_instance);
    TestSchema->register_source(
        'Bar', TestSchema::Result::Bar->result_source_instance);

    # db prepare -a: detects drift (new table 'bars'), auto-bumps
    my $out_prep = '';
    {
        open my $fh, '>', \$out_prep;
        local *STDOUT = $fh;
        local *STDERR = $fh;
        eval { $app->commands->run('db', 'prepare', '-y', '-a'); 1 };
    }
    like($out_prep, qr/Done/, 'prepare -a completed')
        or diag "prepare -a: $out_prep";

    # Fixtures for BOTH plugins should be in v2 directory
    my $fix_v2 = $app->home->child('share', 'fixtures', '2');
    ok(-d $fix_v2, 'fixtures v2 directory exists');
    ok(-f $fix_v2->child('conf', 'foo.json'), 'foo fixture config in v2');
    ok(-f $fix_v2->child('conf', 'bars.json'), 'bars fixture config in v2');

    # db upgrade: apply v1→v2 migration (creates 'bars' table)
    my $out_upg = '';
    {
        open my $fh, '>', \$out_upg;
        local *STDOUT = $fh;
        local *STDERR = $fh;
        eval { $app->commands->run('db', 'upgrade'); 1 };
    }
    like($out_upg, qr/Done/, 'upgrade completed')
        or diag "upgrade: $out_upg";

    # db populate: loads fixtures from v2 directory (no --set).
    # fixtures_loaded already has 'foo' (from v1) → skipped.
    # 'bars' is new → loaded. This is the fondation_upgrade flow.
    my $out_pop = '';
    {
        open my $fh, '>', \$out_pop;
        local *STDOUT = $fh;
        local *STDERR = $fh;
        eval { $app->commands->run('db', 'populate'); 1 };
    }
    like($out_pop, qr/Populate complete/, 'v2 populate completes')
        or diag "v2 populate: $out_pop";
    like($out_pop, qr/Skipping already-loaded/, 'skips already-loaded foo set')
        or diag "v2 populate: $out_pop";
    like($out_pop, qr/foo/, 'foo identified as already-loaded')
        or diag "v2 populate: $out_pop";

    # Verify both tables have data
    my $native = TestSchema->connect("dbi:SQLite:dbname=$dbfile");
    my @foos = $native->resultset('Foo')->all;
    my @bars = $native->resultset('Bar')->all;
    is(scalar @foos, 1, 'foos still has data after upgrade');
    is(scalar @bars, 1, 'bars has data after v2 populate');
    is($bars[0]->name, 'beta', 'bars row has correct name');
}

done_testing;
