#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use Mojo::JSON qw(decode_json);
use File::Temp 'tempdir';
use FindBin;
use lib "$FindBin::Bin/../lib";
use lib "$FindBin::Bin/lib";
use lib "$FindBin::Bin/../../Mojolicious-Plugin-Fondation/lib";

use Mojolicious::Plugin::Fondation::TestHelper qw(create_test_app);

# ==========================================================================
# Helper: build a test app with Fondation + DBIx::Async + TestOpenAPI
# ==========================================================================

sub build_app {
    my $tmpdir = tempdir(CLEANUP => 1);
    my $dbfile = "$tmpdir/test.db";
    my $app    = create_test_app($tmpdir);

    $app->plugin('Fondation' => {
        dependencies => [
            {'Fondation::Model::DBIx::Async' => {
                backends => [
                    test => {
                        dsn          => "dbi:SQLite:dbname=$dbfile",
                        schema_class => 'TestSchema',
                        workers      => 1,
                    },
                ],
                models => {
                    foo => {source => 'Foo'},
                    bar => {source => 'Bar'},
                    baz => {source => 'Baz'},
                },
            }},
            {'Fondation::TestOpenAPI' => {}},   # openapi_exclude => ['bazs'] is in its fondation_meta
            {'Fondation::OpenAPI' => {}},
        ],
    });

    return $app;
}

# ==========================================================================
# Helper: generate spec by calling internal methods (avoid exit())
# ==========================================================================

sub generate_spec {
    my ($app) = @_;

    my $config = $app->defaults->{'openapi.config'};
    require Mojolicious::Plugin::Fondation::OpenAPI::Command::openapi;
    my $cmd = Mojolicious::Plugin::Fondation::OpenAPI::Command::openapi->new(app => $app);

    my $schema_class = $cmd->_get_schema_class($app, $config);
    return $cmd->_build_spec($schema_class, $app, $config);
}

# ==========================================================================
# 1. Baz (pivot table) is excluded from schemas
# ==========================================================================

{
    my $app  = build_app;
    my $spec = generate_spec($app);

    my $schemas = $spec->{components}{schemas};

    # Verify Foos and Bars are still present
    ok(exists $schemas->{Foo}, 'Foo canonical schema exists');
    ok(exists $schemas->{Bar}, 'Bar canonical schema exists');

    # Baz MUST NOT be in schemas (excluded)
    ok(!exists $schemas->{Baz},        'Baz schema absent (excluded)');
    ok(!exists $schemas->{BazCreate},  'no BazCreate (excluded)');
    ok(!exists $schemas->{BazUpdate},  'no BazUpdate (excluded)');
    ok(!exists $schemas->{BazRead},    'no BazRead (excluded)');
    ok(!exists $schemas->{BazList},    'no BazList (excluded)');
    ok(!exists $schemas->{BazPatch},   'no BazPatch (excluded)');
}

# ==========================================================================
# 2. Baz paths are absent from the spec
# ==========================================================================

{
    my $app  = build_app;
    my $spec = generate_spec($app);

    # Foos and Bars paths exist
    ok(exists $spec->{paths}{'/foo'},      '/foo path exists');
    ok(exists $spec->{paths}{'/foo/{id}'}, '/foo/{id} path exists');
    ok(exists $spec->{paths}{'/bar'},      '/bar path exists');
    ok(exists $spec->{paths}{'/bar/{id}'}, '/bar/{id} path exists');

    # Baz paths must NOT exist
    ok(!exists $spec->{paths}{'/baz'},      '/baz path absent (excluded)');
    ok(!exists $spec->{paths}{'/baz/{id}'}, '/baz/{id} path absent (excluded)');
}

# ==========================================================================
# 3. openapi_exclude skips by table_name, not Result class name
# ==========================================================================

{
    my $app  = build_app;
    my $spec = generate_spec($app);

    # The exclusion key is the DBIx::Class source name (table name),
    # not the PascalCase Result name. Verify Baz (PascalCase) is
    # correctly excluded because its table_name ('bazs') matches.
    my $schemas = $spec->{components}{schemas};
    ok(!exists $schemas->{Baz}, 'table_name "bazs" exclusion also hides PascalCase Baz');
}

done_testing;
