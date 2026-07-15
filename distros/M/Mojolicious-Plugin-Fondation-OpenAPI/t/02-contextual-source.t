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

sub generate_spec {
    my ($app) = @_;
    my $config = $app->defaults->{'openapi.config'};
    require Mojolicious::Plugin::Fondation::OpenAPI::Command::openapi;
    my $cmd = Mojolicious::Plugin::Fondation::OpenAPI::Command::openapi->new(app => $app);
    my $schema_class = $cmd->_get_schema_class($app, $config);
    return $cmd->_build_spec($schema_class, $app, $config);
}

# ==========================================================================
# 1. Foo -- contextual: FooCreate generated, FooUpdate NOT (same as canonical)
# ==========================================================================

{
    my $app  = build_app;
    my $spec = generate_spec($app);

    my $schemas = $spec->{components}{schemas};
    ok(exists $schemas->{Foo},       'Foo canonical schema exists');
    ok(exists $schemas->{FooCreate}, 'FooCreate generated (writeOnly + required differs)');
    ok(exists $schemas->{FooUpdate}, 'FooUpdate generated (writeOnly added, required same)');
    ok(!exists $schemas->{FooRead},   'no FooRead (same as canonical)');
    ok(!exists $schemas->{FooList},   'no FooList (same as canonical)');
}

# ==========================================================================
# 2. Foo canonical -- password present (writeOnly) but NOT in required
# ==========================================================================

{
    my $app  = build_app;
    my $spec = generate_spec($app);

    my $foo   = $spec->{components}{schemas}{Foo};
    my $props = $foo->{properties};
    my $req   = $foo->{required};

    # Structural properties
    is($props->{id}{type},     'integer', 'id type integer');
    ok($props->{id}{readOnly}, 'id readOnly (auto_increment)');
    is($props->{name}{type},        'string', 'name type string');
    is($props->{name}{maxLength},   100,      'name maxLength 100 (size)');
    is($props->{name}{minLength},   3,        'name minLength 3 (extra openapi)');
    is($props->{email}{type},       'string', 'email type string');
    is($props->{email}{maxLength},  200,      'email maxLength 200 (size)');
    is($props->{email}{format},     'email',  'email format email (extra openapi)');

    # password -- absent from canonical (writeOnly)
    ok(!exists $props->{password}, 'password absent from canonical (writeOnly)');

    # active, created_at, age, score
    is($props->{active}{type},    'integer', 'active type integer');
    is_deeply($props->{active}{enum}, [0, 1], 'active enum [0, 1] (extra openapi)');
    is($props->{active}{default}, 1, 'active default 1 (default_value)');
    ok($props->{active}{nullable},  'active nullable');
    is($props->{created_at}{type},   'string',    'created_at type string');
    ok($props->{created_at}{readOnly}, 'created_at readOnly (naming convention)');
    is($props->{created_at}{format}, 'date-time', 'created_at format date-time (implicit from datetime)');
    is($props->{age}{type},    'integer', 'age type integer');
    is($props->{age}{minimum}, 0,        'age minimum 0 (extra openapi)');
    ok($props->{age}{nullable}, 'age nullable');
    is($props->{score}{type},   'number', 'score type number (implicit from float)');
    is($props->{score}{format}, 'float',  'score format float (implicit from float)');
    ok($props->{score}{nullable}, 'score nullable');

    # Description fallback
    is($props->{name}{description}, 'Name', 'name description auto-generated');
    is($props->{id}{description},   'Id',   'id description auto-generated');

    # required -- password absent (writeOnly), id absent (readOnly)
    ok((grep { $_ eq 'name' } @$req),  'name required (NOT NULL)');
    ok((grep { $_ eq 'email' } @$req), 'email required (NOT NULL)');
    ok(!(grep { $_ eq 'password' } @$req),   'password NOT required (writeOnly excluded from canonical)');
    ok(!(grep { $_ eq 'id' } @$req),         'id NOT required (readOnly)');
    ok(!(grep { $_ eq 'active' } @$req),     'active NOT required (nullable)');
    ok(!(grep { $_ eq 'created_at' } @$req), 'created_at NOT required (readOnly)');
    ok(!(grep { $_ eq 'age' } @$req),        'age NOT required (nullable)');
    ok(!(grep { $_ eq 'score' } @$req),      'score NOT required (nullable)');
}

# ==========================================================================
# 3. FooCreate -- password in properties AND required
# ==========================================================================

{
    my $app  = build_app;
    my $spec = generate_spec($app);

    my $foo   = $spec->{components}{schemas}{FooCreate};
    my $props = $foo->{properties};
    my $req   = $foo->{required};

    ok(exists $props->{password}, 'password present in FooCreate (writeOnly added)');
    is($props->{password}{type},       'string',   'password type string');
    ok($props->{password}{writeOnly},  'password writeOnly');
    is($props->{password}{minLength},  8,          'password minLength 8');

    ok((grep { $_ eq 'name' } @$req),     'name required in create');
    ok((grep { $_ eq 'email' } @$req),    'email required in create');
    ok((grep { $_ eq 'password' } @$req), 'password required in create (create.required => 1)');
    ok(!(grep { $_ eq 'id' } @$req),      'id NOT required in create (readOnly)');
}

# ==========================================================================
# 4. FooUpdate -- password in properties, NOT in required
# ==========================================================================

{
    my $app  = build_app;
    my $spec = generate_spec($app);

    my $foo   = $spec->{components}{schemas}{FooUpdate};
    my $props = $foo->{properties};
    my $req   = $foo->{required};

    ok(exists $props->{password}, 'password present in FooUpdate (writeOnly added)');
    ok(!(grep { $_ eq 'password' } @$req), 'password NOT required in FooUpdate');
    ok((grep { $_ eq 'name' } @$req),      'name required in update');
    ok((grep { $_ eq 'email' } @$req),     'email required in update');
}

# ==========================================================================
# 5. Foo paths -- create uses FooCreate, update uses FooUpdate, others use Foo
# ==========================================================================

{
    my $app  = build_app;
    my $spec = generate_spec($app);

    # GET /foo -- list: array of Foo
    my $list = $spec->{paths}{'/foo'}{get};
    is($list->{operationId}, 'list_foo', 'GET /foo operationId');
    my $list_items = $list->{responses}{'200'}{content}{'application/json'}{schema}{items};
    is($list_items->{'$ref'}, '#/components/schemas/Foo', 'list returns array of Foo');

    # POST /foo -- create: FooCreate
    my $create = $spec->{paths}{'/foo'}{post};
    is($create->{operationId}, 'create_foo', 'POST /foo operationId');
    is($create->{requestBody}{content}{'application/json'}{schema}{'$ref'},
        '#/components/schemas/FooCreate', 'POST /foo uses FooCreate');

    # GET /foo/{id} -- read: Foo
    my $read = $spec->{paths}{'/foo/{id}'}{get};
    is($read->{operationId}, 'read_foo', 'GET /foo/{id} operationId');
    is($read->{responses}{'200'}{content}{'application/json'}{schema}{'$ref'},
        '#/components/schemas/Foo', 'GET /foo/{id} uses Foo');

    # PUT /foo/{id} -- update: FooUpdate
    my $update = $spec->{paths}{'/foo/{id}'}{put};
    is($update->{operationId}, 'update_foo', 'PUT /foo/{id} operationId');
    is($update->{requestBody}{content}{'application/json'}{schema}{'$ref'},
        '#/components/schemas/FooUpdate', 'PUT /foo/{id} uses FooUpdate');

    # DELETE /foo/{id}
    my $delete = $spec->{paths}{'/foo/{id}'}{delete};
    is($delete->{operationId}, 'delete_foo', 'DELETE /foo/{id} operationId');
}

done_testing;
