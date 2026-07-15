#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use Mojo::File 'path';
use Mojo::JSON qw(decode_json false true);
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
                },
            }},
            {'Fondation::TestOpenAPI' => {}},
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
# 1. Bar -- simple source: no contextual rules → only canonical schema
# ==========================================================================

{
    my $app  = build_app;
    my $spec = generate_spec($app);

    my $schemas = $spec->{components}{schemas};
    ok(exists $schemas->{Bar}, 'Bar canonical schema exists');
    ok(!exists $schemas->{BarCreate}, 'no BarCreate (identical to canonical)');
    ok(!exists $schemas->{BarUpdate}, 'no BarUpdate (identical to canonical)');
    ok(!exists $schemas->{BarRead},   'no BarRead (identical to canonical)');
    ok(!exists $schemas->{BarList},   'no BarList (identical to canonical)');
    ok(exists $schemas->{BarPatch},   'BarPatch exists (required differs)');
    ok(exists $schemas->{FooPatch},   'FooPatch exists');
    is(scalar keys %$schemas, 6, '6 schemas (Bar, BarPatch, Foo, FooCreate, FooUpdate, FooPatch)');

    # Bar properties
    my $bar = $schemas->{Bar};
    my $props = $bar->{properties};
    is($props->{id}{type},           'integer', 'id type integer');
    ok($props->{id}{readOnly},       'id readOnly (auto_increment)');
    is($props->{title}{type},        'string',  'title type string');
    is($props->{title}{maxLength},   200,       'title maxLength 200 (size)');
    is($props->{title}{minLength},   3,         'title minLength 3 (extra openapi)');
    is($props->{body}{type},         'string',  'body type string');
    is($props->{body}{maxLength},    10000,     'body maxLength 10000 (extra openapi)');
    ok($props->{body}{nullable},     'body nullable');
    is($props->{is_published}{type}, 'boolean', 'is_published type boolean (data_type match)');
    is($props->{is_published}{default}, 0,      'is_published default 0');
    is($props->{start_date}{type},   'string',  'start_date type string');
    is($props->{start_date}{format}, 'date',    'start_date format date (implicit from data_type)');
    is($props->{count}{type},        'integer', 'count type integer');
    is($props->{count}{default},     0,         'count default 0');
    is($props->{count}{minimum},     0,         'count minimum 0 (extra openapi)');

    # Bar required
    my $req = $bar->{required};
    ok((grep { $_ eq 'title' } @$req), 'title required (NOT NULL)');
    ok(!(grep { $_ eq 'id' } @$req),   'id NOT required (readOnly)');
    ok(!(grep { $_ eq 'body' } @$req), 'body NOT required (nullable)');

    # BarPatch: required key must be absent (empty required is invalid in OpenAPI 3.0)
    my $barpatch = $schemas->{BarPatch};
    ok(!exists $barpatch->{required}, 'BarPatch has no required key (all fields optional)');
    is(scalar keys %{$barpatch->{properties}}, scalar keys %{$bar->{properties}},
        'BarPatch has same property count as Bar');
}


# ==========================================================================
# 2. Bar paths -- all reference the canonical Bar schema
# ==========================================================================

{
    my $app  = build_app;
    my $spec = generate_spec($app);

    # GET /bar -- list
    my $list = $spec->{paths}{'/bar'}{get};
    is($list->{operationId}, 'list_bar', 'GET /bar operationId');
    is($list->{'x-mojo-to'}, 'Bar#list', 'GET /bar x-mojo-to');
    my $list_schema = $list->{responses}{'200'}{content}{'application/json'}{schema};
    is($list_schema->{type}, 'array', 'list response is array');
    is($list_schema->{items}{'$ref'}, '#/components/schemas/Bar', 'array of Bar');

    # POST /bar -- create
    my $create = $spec->{paths}{'/bar'}{post};
    is($create->{operationId}, 'create_bar', 'POST /bar operationId');
    is($create->{'x-mojo-to'}, 'Bar#create', 'POST /bar x-mojo-to');
    is($create->{requestBody}{content}{'application/json'}{schema}{'$ref'},
        '#/components/schemas/Bar', 'POST /bar uses Bar (no BarCreate)');

    # GET /bar/{id} -- read
    my $read = $spec->{paths}{'/bar/{id}'}{get};
    is($read->{operationId}, 'read_bar', 'GET /bar/{id} operationId');
    is($read->{'x-mojo-to'}, 'Bar#read', 'GET /bar/{id} x-mojo-to');
    is($read->{responses}{'200'}{content}{'application/json'}{schema}{'$ref'},
        '#/components/schemas/Bar', 'GET /bar/{id} uses Bar');

    # PUT /bar/{id} -- update
    my $update = $spec->{paths}{'/bar/{id}'}{put};
    is($update->{operationId}, 'update_bar', 'PUT /bar/{id} operationId');
    is($update->{'x-mojo-to'}, 'Bar#update', 'PUT /bar/{id} x-mojo-to');
    is($update->{requestBody}{content}{'application/json'}{schema}{'$ref'},
        '#/components/schemas/Bar', 'PUT /bar/{id} uses Bar (no BarUpdate)');

    # PATCH /bar/{id} -- partial update
    my $patch = $spec->{paths}{'/bar/{id}'}{patch};
    is($patch->{operationId}, 'patch_bar', 'PATCH /bar/{id} operationId');
    is($patch->{'x-mojo-to'}, 'Bar#update', 'PATCH /bar/{id} x-mojo-to');
    is($patch->{requestBody}{content}{'application/json'}{schema}{'$ref'},
        '#/components/schemas/BarPatch', 'PATCH /bar/{id} uses BarPatch');

    # DELETE /bar/{id}
    my $delete = $spec->{paths}{'/bar/{id}'}{delete};
    is($delete->{operationId}, 'delete_bar', 'DELETE /bar/{id} operationId');
    is($delete->{'x-mojo-to'}, 'Bar#delete', 'DELETE /bar/{id} x-mojo-to');
}

# ==========================================================================
# 3. Bar x-auth – default convention {moniker_lc}_{operation}
# ==========================================================================

{
    my $app  = build_app;
    my $spec = generate_spec($app);

    # GET /bar – list
    my $list = $spec->{paths}{'/bar'}{get};
    is_deeply($list->{'x-auth'}, {permissions => ['bar_list']},
        'GET /bar x-auth bar_list');

    # POST /bar – create
    my $create = $spec->{paths}{'/bar'}{post};
    is_deeply($create->{'x-auth'}, {permissions => ['bar_create']},
        'POST /bar x-auth bar_create');

    # GET /bar/{id} – read
    my $read = $spec->{paths}{'/bar/{id}'}{get};
    is_deeply($read->{'x-auth'}, {permissions => ['bar_read']},
        'GET /bar/{id} x-auth bar_read');

    # PUT /bar/{id} – update
    my $update = $spec->{paths}{'/bar/{id}'}{put};
    is_deeply($update->{'x-auth'}, {permissions => ['bar_update']},
        'PUT /bar/{id} x-auth bar_update');

    # PATCH /bar/{id} – partial update (reuses update permissions)
    my $patch_xa = $spec->{paths}{'/bar/{id}'}{patch};
    is_deeply($patch_xa->{'x-auth'}, {permissions => ['bar_update']},
        'PATCH /bar/{id} x-auth bar_update (reuses update)');

    # DELETE /bar/{id}
    my $delete = $spec->{paths}{'/bar/{id}'}{delete};
    is_deeply($delete->{'x-auth'}, {permissions => ['bar_delete']},
        'DELETE /bar/{id} x-auth bar_delete');
}

done_testing;
