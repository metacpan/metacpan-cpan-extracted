use strict;
use warnings;
use Test::More;
use Mojolicious;
use Mojo::File 'path';
use File::Temp 'tempdir';
use FindBin;
use lib "$FindBin::Bin/../lib";
use lib "$FindBin::Bin/lib";

use JSON::MaybeXS 'decode_json';

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

sub build_app {
    my (%opts) = @_;
    my $tmpdir = $opts{tmpdir} // tempdir(CLEANUP => 1);
    my $dbfile = "$tmpdir/test.db";

    my $app = Mojolicious->new;
    $app->moniker('TestApp');
    $app->log->level('fatal');
    $app->home(path($tmpdir));

    $app->plugin('Fondation' => {
        dependencies => [
            { 'Fondation::Model::DBIx::Async' => {
                backends => [
                    main => {
                        dsn          => "dbi:SQLite:dbname=$dbfile",
                        schema_class => 'TestSchema',
                        workers      => 1,
                    },
                ],
                models => {
                    foo => { source => 'foos', backend => 'main' },
                },
            }},
            { 'Fondation::MigrationDBIx' => {} },
        ],
    });

    require TestSchema;
    require TestSchema::Result::Foo;
    TestSchema->register_source(
        'foos', TestSchema::Result::Foo->result_source_instance);

    return $app;
}

# ==========================================================================
# 1. First prepare -- saves sig, no drift
# ==========================================================================
{
    my $tmpdir = tempdir(CLEANUP => 1);
    my $app = build_app(tmpdir => $tmpdir);
    my $mig_dir = $app->home->child('share', 'migrations');

    capture_run($app, 'db', 'prepare', '-y');

    my $sig_file = $mig_dir->child('.schema-sig.json');
    ok(-f $sig_file, '.schema-sig.json created');

    my $sig_data = eval { decode_json($sig_file->slurp) };
    ok($sig_data->{version}, 'sig has version');
    ok($sig_data->{sources}{foos}, 'sig has foos source');

    my $c = $app->build_controller;
    my $drift = $c->schema_drift;
    ok(!$drift->{has_drift}, 'no drift after first prepare');
}

# ==========================================================================
# 2. schema_sig helper returns canonical structure
# ==========================================================================
{
    my $tmpdir = tempdir(CLEANUP => 1);
    my $app = build_app(tmpdir => $tmpdir);
    my $c = $app->build_controller;

    my $sig = $c->schema_sig;
    ok($sig->{foos}, 'schema_sig has foos');
    my @col_names = map { $_->{name} } @{$sig->{foos}{columns}};
    ok((grep { $_ eq 'id' } @col_names), 'has id column');
    ok((grep { $_ eq 'name' } @col_names), 'has name column');

    my $id_col;
    for my $col (@{$sig->{foos}{columns}}) {
        $id_col = $col if $col->{name} eq 'id';
    }
    is($id_col->{data_type}, 'integer',  'id data_type');
    ok($id_col->{is_auto_increment},     'id auto_increment');
    ok(!$id_col->{is_nullable},          'id not nullable');
}

# ==========================================================================
# 3. Drift detection + auto-bump via -a flag
# ==========================================================================
{
    my $tmpdir = tempdir(CLEANUP => 1);
    my $class  = 'DriftTestSchema';

    # Create a dedicated schema + Result in the tempdir
    my $lib_dir = path($tmpdir, 'lib');
    $lib_dir->make_path;

    $lib_dir->child('DriftTestSchema.pm')->spurt(<<"SCHEMA");
package $class;
use base 'DBIx::Class::Schema';
our \$VERSION = '1';
1;
SCHEMA

    $lib_dir->child('DriftTestSchema', 'Result')->make_path;
    $lib_dir->child('DriftTestSchema', 'Result', 'Foo.pm')->spurt(<<"RESULT");
package DriftTestSchema::Result::Foo;
use base 'DBIx::Class::Core';
__PACKAGE__->table('foos');
__PACKAGE__->add_columns(
    id   => { data_type => 'integer', is_auto_increment => 1, is_nullable => 0 },
    name => { data_type => 'varchar', is_nullable => 0, size => 100 },
);
__PACKAGE__->set_primary_key('id');
1;
RESULT

    unshift @INC, "$tmpdir/lib";

    # Build app with this dedicated schema
    my $dbfile = "$tmpdir/test.db";
    my $app = Mojolicious->new;
    $app->moniker('TestApp');
    $app->log->level('fatal');
    $app->home(path($tmpdir));

    require DriftTestSchema;
    require DriftTestSchema::Result::Foo;

    $app->plugin('Fondation' => {
        dependencies => [
            { 'Fondation::Model::DBIx::Async' => {
                backends => [
                    main => {
                        dsn          => "dbi:SQLite:dbname=$dbfile",
                        schema_class => 'DriftTestSchema',
                        workers      => 1,
                    },
                ],
                models => {
                    foo => { source => 'foos', backend => 'main' },
                },
            }},
            { 'Fondation::MigrationDBIx' => {} },
        ],
    });

    DriftTestSchema->register_source(
        'foos', DriftTestSchema::Result::Foo->result_source_instance);

    # First prepare
    capture_run($app, 'db', 'prepare', '-y');

    # Modify the Result -- add a column
    $lib_dir->child('DriftTestSchema', 'Result', 'Foo.pm')->spurt(<<"RESULT2");
package DriftTestSchema::Result::Foo;
use base 'DBIx::Class::Core';
__PACKAGE__->table('foos');
__PACKAGE__->add_columns(
    id    => { data_type => 'integer', is_auto_increment => 1, is_nullable => 0 },
    name  => { data_type => 'varchar', is_nullable => 0, size => 100 },
    score => { data_type => 'integer', is_nullable => 1 },
);
__PACKAGE__->set_primary_key('id');
1;
RESULT2

    # Delete from %INC to force reload of modified Result
    delete $INC{'DriftTestSchema/Result/Foo.pm'};

    # Rebuild app with modified schema
    my $app2 = Mojolicious->new;
    $app2->moniker('TestApp');
    $app2->log->level('fatal');
    $app2->home(path($tmpdir));

    $app2->plugin('Fondation' => {
        dependencies => [
            { 'Fondation::Model::DBIx::Async' => {
                backends => [
                    main => {
                        dsn          => "dbi:SQLite:dbname=$dbfile",
                        schema_class => 'DriftTestSchema',
                        workers      => 1,
                    },
                ],
                models => {
                    foo => { source => 'foos', backend => 'main' },
                },
            }},
            { 'Fondation::MigrationDBIx' => {} },
        ],
    });

    require DriftTestSchema::Result::Foo;
    DriftTestSchema->register_source(
        'foos', DriftTestSchema::Result::Foo->result_source_instance);

    # Drift should be detected
    my $c2 = $app2->build_controller;
    my $drift = $c2->schema_drift;
    ok($drift->{has_drift}, 'drift detected after column added')
        or diag explain $drift;

    my $ch = $drift->{changes}{foos};
    ok($ch->{added} && (grep { $_ eq 'score' } @{$ch->{added}}),
        'score column in added list');

    # prepare without -a → warns about drift
    my $out = capture_run($app2, 'db', 'prepare', '-y');
    like($out, qr/drifted/,   'prepare reports drift');
    like($out, qr/prepare -a/, 'suggests -a flag');

    # prepare with -a → auto-bumps and succeeds
    my $out2 = capture_run($app2, 'db', 'prepare', '-y', '-a');
    like($out2, qr/Bumped.*from 1 to 2/s, 'auto-bumped version');
    like($out2, qr/Done/, 'prepare succeeded after bump');

    # Verify version was bumped in file
    my $content = $lib_dir->child('DriftTestSchema.pm')->slurp;
    like($content, qr/\$VERSION\s*=\s*['"]?2['"]?/, 'VERSION bumped to 2 in file');
}

# ==========================================================================
# 4. schema_drift without any prepare -- no drift
# ==========================================================================
{
    my $tmpdir = tempdir(CLEANUP => 1);
    my $app = build_app(tmpdir => $tmpdir);
    my $c = $app->build_controller;
    my $drift = $c->schema_drift;
    ok(!$drift->{has_drift}, 'no drift when no sig file exists');
}

done_testing;
