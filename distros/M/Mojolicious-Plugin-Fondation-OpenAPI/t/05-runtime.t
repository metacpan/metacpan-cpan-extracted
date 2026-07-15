#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use Mojo::File 'path';
use Mojo::JSON qw(encode_json decode_json true);
use Test::Mojo;
use File::Temp 'tempdir';
use FindBin;
use lib "$FindBin::Bin/../lib";
use lib "$FindBin::Bin/lib";
use lib "$FindBin::Bin/../../Mojolicious-Plugin-Fondation/lib";

use Mojolicious::Plugin::Fondation::TestHelper qw(create_test_app);

# ==========================================================================
# 1. No spec file → warning, no crash
# ==========================================================================

{
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
                },
            }},
            {'Fondation::TestOpenAPI' => {}},
            {'Fondation::OpenAPI' => {}},
        ],
    });

    my $c = $app->build_controller;
    ok(!$c->has_helper('openapi.validate'), 'openapi helper not registered without spec');
}

# ==========================================================================
# 2. Spec file exists → OpenAPI plugin loaded
# ==========================================================================

{
    my $tmpdir = tempdir(CLEANUP => 1);
    my $dbfile = "$tmpdir/test.db";
    my $app    = create_test_app($tmpdir);

    # MUST create spec BEFORE plugin loading
    my $spec_dir = $app->home->child('share');
    $spec_dir->make_path;
    $spec_dir->child('openapi.json')->spurt(encode_json({
        openapi => '3.0.3',
        info    => { title => 'Test', version => '1.0' },
        paths   => {},
    }));

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
                },
            }},
            {'Fondation::TestOpenAPI' => {}},
            {'Fondation::OpenAPI' => {}},
        ],
    });

    my $c = $app->build_controller;
    ok($c->has_helper('openapi.validate'), 'openapi helper registered with spec');
}

# ==========================================================================
# 3. Development mode → Swagger UI routes added
# ==========================================================================

{
    my $tmpdir = tempdir(CLEANUP => 1);
    my $dbfile = "$tmpdir/test.db";
    my $app    = create_test_app($tmpdir);
    $app->mode('development');

    # MUST create spec BEFORE plugin loading
    my $spec_dir = $app->home->child('share');
    $spec_dir->make_path;
    $spec_dir->child('openapi.json')->spurt(encode_json({
        openapi => '3.0.3',
        info    => { title => 'Test', version => '1.0' },
        paths   => {},
    }));

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
                },
            }},
            {'Fondation::TestOpenAPI' => {}},
            {'Fondation::OpenAPI' => {}},
        ],
    });

    ok(defined $app->routes->find('swagger'), 'GET /swagger route exists in dev mode');

    # /openapi.json route -- find by scanning children (dot in name tricky for find())
    my $found_json = 0;
    for my $child (@{$app->routes->children}) {
        my $p = $child->pattern->unparsed // '';
        if ($p eq '/openapi.json') {
            $found_json = 1;
            last;
        }
    }
    ok($found_json, 'GET /openapi.json route exists in dev mode');
}

# ==========================================================================
# 4. Production mode → no Swagger UI routes
# ==========================================================================

{
    my $tmpdir = tempdir(CLEANUP => 1);
    my $dbfile = "$tmpdir/test.db";
    my $app    = create_test_app($tmpdir);
    $app->mode('production');

    # MUST create spec BEFORE plugin loading
    my $spec_dir = $app->home->child('share');
    $spec_dir->make_path;
    $spec_dir->child('openapi.json')->spurt(encode_json({
        openapi => '3.0.3',
        info    => { title => 'Test', version => '1.0' },
        paths   => {},
    }));

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
                },
            }},
            {'Fondation::TestOpenAPI' => {}},
            {'Fondation::OpenAPI' => {}},
        ],
    });

    my $swagger = $app->routes->find('swagger');
    ok(!defined $swagger, 'no GET /swagger route in production mode');
}

# ==========================================================================
# 5. x-auth translated to requires() via openapi_routes_added hook
# ==========================================================================

{
    my $tmpdir = tempdir(CLEANUP => 1);
    my $app    = create_test_app($tmpdir);

    # Load Fondation core for helpers (has_helper, etc.)
    $app->plugin('Fondation');

    # Build a spec with x-auth on some routes
    my $spec = {
        openapi => '3.0.3',
        info    => {title => 'Requires Test', version => '1.0'},
        servers => [{url => ''}],
        paths   => {
            '/public' => {
                get => {
                    operationId => 'public_list',
                    responses   => {'200' => {description => 'OK'}},
                },
            },
            '/protected' => {
                get => {
                    operationId => 'protected_list',
                    'x-auth'    => {permissions => ['test_read']},
                    responses   => {'200' => {description => 'OK'}},
                },
            },
            '/multi' => {
                get => {
                    operationId => 'multi_list',
                    'x-auth' => {
                        permissions => ['perm_a', 'perm_b'],
                        groups      => ['group_x'],
                    },
                    responses => {'200' => {description => 'OK'}},
                },
            },
        },
    };

    my $spec_file = $app->home->child('share', 'openapi.json');
    $spec_file->dirname->make_path;
    $spec_file->spurt(encode_json($spec));

    # Register named routes BEFORE loading OpenAPI
    my $r = $app->routes;
    $r->get('/public')->to(cb => sub {
        shift->render(openapi => {status => 'ok'}, status => 200);
    })->name('public_list');
    $r->get('/protected')->to(cb => sub {
        shift->render(openapi => {status => 'ok'}, status => 200);
    })->name('protected_list');
    $r->get('/multi')->to(cb => sub {
        shift->render(openapi => {status => 'ok'}, status => 200);
    })->name('multi_list');

    # Register the hook (same logic as fondation_finalyze)
    $app->plugins->on(openapi_routes_added => sub {
        my ($openapi, $routes) = @_;
        $routes ||= [];
        for my $route (@$routes) {
            my $defaults = $route->pattern->defaults;
            my $path     = $defaults->{'openapi.path'};
            my $method   = $defaults->{'openapi.method'};
            next unless $path && $method;

            my $op_spec = $openapi->validator->get([paths => $path, $method]);
            my $x_auth  = $op_spec->{'x-auth'} // {};

            my @conditions;
            push @conditions, 'fondation.perm'  => $_ for @{$x_auth->{permissions} // []};
            push @conditions, 'fondation.group' => $_ for @{$x_auth->{groups}     // []};
            $route->requires(@conditions) if @conditions;
        }
    });

    # Load OpenAPI and capture the instance
    my $openapi_instance = $app->plugin(OpenAPI => {
        url => $spec_file->to_string,
    });

    # Find routes via OpenAPI's route tree (they were moved by add_child)
    my $pub = $openapi_instance->route->find('public_list');
    ok($pub, '/public route found');
    my $pub_req = $pub->requires || [];
    is(scalar @$pub_req, 0, '/public has no requires (public)')
        or diag explain $pub_req;

    my $prot = $openapi_instance->route->find('protected_list');
    ok($prot, '/protected route found');
    my $prot_req = $prot->requires || [];
    ok((grep { $_ eq 'fondation.perm' } @$prot_req), '/protected has fondation.perm condition');
    ok((grep { $_ eq 'test_read' }      @$prot_req), '/protected has test_read value');

    my $multi = $openapi_instance->route->find('multi_list');
    ok($multi, '/multi route found');
    my $multi_req = $multi->requires || [];
    ok((grep { $_ eq 'perm_a' }  @$multi_req), '/multi has perm_a')
        or diag "requires: " . join(', ', @$multi_req);
    ok((grep { $_ eq 'perm_b' }  @$multi_req), '/multi has perm_b')
        or diag "requires: " . join(', ', @$multi_req);
    ok((grep { $_ eq 'group_x' } @$multi_req), '/multi has group_x');
}

done_testing;
