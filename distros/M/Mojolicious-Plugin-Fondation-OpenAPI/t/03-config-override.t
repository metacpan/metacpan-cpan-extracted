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
    my ($openapi_config) = @_;
    my $tmpdir = tempdir(CLEANUP => 1);
    my $dbfile = "$tmpdir/test.db";
    my $app    = create_test_app($tmpdir);

    my $openapi_cfg = $openapi_config // {};

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
            {'Fondation::OpenAPI' => $openapi_cfg},
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
# 1. Config overrides extra->{openapi} flat keys
# ==========================================================================

{
    my $app = build_app({
        schemas => {
            Bar => {
                columns => {
                    title => {
                        maxLength => 50,      # override size=200 from DBIx
                        minLength => 5,       # override extra->{openapi} minLength=3
                    },
                },
            },
        },
    });

    my $spec  = generate_spec($app);
    my $title = $spec->{components}{schemas}{Bar}{properties}{title};

    is($title->{maxLength}, 50, 'config overrides size: maxLength 50');
    is($title->{minLength}, 5,  'config overrides extra openapi: minLength 5');
}

# ==========================================================================
# 2. Config overrides contextual required
# ==========================================================================

{
    # Bar normally has no contextual rules.
    # Force a create.required on is_published via config.
    my $app = build_app({
        schemas => {
            Bar => {
                columns => {
                    is_published => {
                        create => { required => 1 },
                    },
                },
            },
        },
    });

    my $spec = generate_spec($app);
    my $schemas = $spec->{components}{schemas};

    ok(exists $schemas->{BarCreate}, 'BarCreate generated (config added create.required)');

    my $req = $schemas->{BarCreate}{required};
    ok((grep { $_ eq 'is_published' } @$req), 'is_published required in BarCreate (config)');
}

# ==========================================================================
# 3. Config overrides implicit rule (readOnly)
# ==========================================================================

{
    # Force id to NOT be readOnly (overrides auto_increment implicit rule)
    my $app = build_app({
        schemas => {
            Foo => {
                columns => {
                    id => {
                        readOnly => 0,
                    },
                },
            },
        },
    });

    my $spec = generate_spec($app);
    my $id   = $spec->{components}{schemas}{Foo}{properties}{id};

    ok(!$id->{readOnly}, 'id readOnly overridden to false via config');

    # id should now be required (NOT NULL + not readOnly)
    my $req = $spec->{components}{schemas}{Foo}{required};
    ok((grep { $_ eq 'id' } @$req), 'id now required (readOnly=0)');
}

# ==========================================================================
# 4. Config overrides structural required (force optional on NOT NULL column)
# ==========================================================================

{
    my $app = build_app({
        schemas => {
            Bar => {
                columns => {
                    title => {
                        update => { required => 0 },
                    },
                },
            },
        },
    });

    my $spec = generate_spec($app);
    my $schemas = $spec->{components}{schemas};

    ok(exists $schemas->{BarUpdate}, 'BarUpdate generated (config removed title from update required)');

    my $req = $schemas->{BarUpdate}{required};
    ok(!(grep { $_ eq 'title' } @$req), 'title NOT required in BarUpdate (config override)');
}

# ==========================================================================
# 5. Config schemas key not present → no effect (graceful)
# ==========================================================================

{
    my $app  = build_app({});
    my $spec = generate_spec($app);

    # Bar should be unchanged
    my $schemas = $spec->{components}{schemas};
    ok(exists $schemas->{Bar}, 'Bar exists without config override');
    ok(!exists $schemas->{BarCreate}, 'no BarCreate without config override');
}

# ==========================================================================
# 6. x-auth config override
# ==========================================================================

{
    my $app = build_app({
        schemas => {
            Foo => {
                x_auth => {
                    create => {
                        permissions => ['admin_create_foo'],
                        groups      => ['admins'],
                    },
                    list => {
                        permissions => [],    # public endpoint
                    },
                },
            },
        },
    });

    my $spec = generate_spec($app);

    # Override: create gets custom permissions + groups
    my $foo_create = $spec->{paths}{'/foo'}{post};
    is_deeply($foo_create->{'x-auth'},
        {permissions => ['admin_create_foo'], groups => ['admins']},
        'x-auth create overridden from config');

    # Override: list is public (empty permissions → x-auth absent)
    my $foo_list = $spec->{paths}{'/foo'}{get};
    ok(!exists $foo_list->{'x-auth'},
        'x-auth absent for public endpoint (permissions: [])');

    # Default: read/update/delete still use convention
    my $foo_read = $spec->{paths}{'/foo/{id}'}{get};
    is_deeply($foo_read->{'x-auth'}, {permissions => ['foo_read']},
        'x-auth read uses default convention');

    my $foo_update = $spec->{paths}{'/foo/{id}'}{put};
    is_deeply($foo_update->{'x-auth'}, {permissions => ['foo_update']},
        'x-auth update uses default convention');

    my $foo_delete = $spec->{paths}{'/foo/{id}'}{delete};
    is_deeply($foo_delete->{'x-auth'}, {permissions => ['foo_delete']},
        'x-auth delete uses default convention');
}

done_testing;
