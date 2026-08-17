#!/usr/bin/env perl
use Mojo::Base -strict;
use Test::More;
use Mojo::File 'path';
use Mojo::JSON qw(encode_json);
use File::Temp 'tempdir';

use Mojolicious;

# ── Integration test: Fondation::CSRF + Mojolicious::Plugin::OpenAPI ────
#
# Loads the CSRF plugin via Fondation (like a real app does, which
# registers the `fondation.csrf` condition and subscribes to the
# `openapi_routes_added` hook), then loads the upstream OpenAPI plugin.
# Verifies that POST/PUT/PATCH/DELETE routes automatically get the
# CSRF condition without any manual hook subscription in the test.

subtest 'CSRF plugin adds fondation.csrf to OpenAPI mutating routes' => sub {
    my $tmpdir = tempdir(CLEANUP => 1);

    # ── Build the app ───────────────────────────────────────────────

    my $app = Mojolicious->new;
    $app->home(Mojo::Home->new($tmpdir));
    $app->log->level('error');
    $app->secrets(['test_secret_32_bytes_minimum']);

    # Load Fondation with the CSRF plugin (auto_protect off — we only
    # test OpenAPI integration here, not around_dispatch).
    $app->plugin('Fondation' => {
        dependencies => [
            { 'Fondation::SessionStore' => { store_dir => "$tmpdir/sessions" }},
            { 'Fondation::CSRF' => { auto_protect => 0 }},
        ],
    });

    # ── Build an OpenAPI spec ───────────────────────────────────────

    my $spec = {
        openapi => '3.0.3',
        info    => { title => 'Integration Test', version => '1.0' },
        servers => [{ url => '' }],
        paths   => {
            '/items' => {
                get    => { operationId => 'list_items',   responses => { '200' => { description => 'OK' }}},
                post   => { operationId => 'create_item',  responses => { '201' => { description => 'Created' }}},
            },
            '/items/{id}' => {
                get    => { operationId => 'read_item',    responses => { '200' => { description => 'OK' }}},
                put    => { operationId => 'update_item',  responses => { '200' => { description => 'OK' }}},
                patch  => { operationId => 'patch_item',   responses => { '200' => { description => 'OK' }}},
                delete => { operationId => 'delete_item',  responses => { '200' => { description => 'OK' }}},
            },
        },
    };

    my $spec_file = $app->home->child('share', 'openapi.json');
    $spec_file->dirname->make_path;
    $spec_file->spurt(encode_json($spec));

    # Register named routes BEFORE loading OpenAPI
    my $r = $app->routes;
    $r->get('/items')->name('list_items');
    $r->post('/items')->name('create_item');
    $r->get('/items/:id')->name('read_item');
    $r->put('/items/:id')->name('update_item');
    $r->patch('/items/:id')->name('patch_item');
    $r->delete('/items/:id')->name('delete_item');

    # ── Load OpenAPI ────────────────────────────────────────────────
    # This triggers openapi_routes_added. The CSRF plugin (loaded above
    # via Fondation) subscribed to this hook in its register() method.
    my $openapi = $app->plugin(OpenAPI => {
        url => $spec_file->to_string,
    });

    # ── Verify: GET routes have NO csrf condition ───────────────────

    for my $name (qw(list_items read_item)) {
        my $route = $openapi->route->find($name);
        ok $route, "GET $name route found";
        my $reqs = $route->requires || [];
        ok(!(grep { $_ eq 'fondation.csrf' } @$reqs),
            "GET $name does NOT have fondation.csrf")
            or diag "requires: " . join(', ', @$reqs);
    }

    # ── Verify: POST/PUT/PATCH/DELETE routes HAVE csrf condition ────

    for my $name (qw(create_item update_item patch_item delete_item)) {
        my $route = $openapi->route->find($name);
        ok $route, "$name route found";
        my $reqs = $route->requires || [];
        ok((grep { $_ eq 'fondation.csrf' } @$reqs),
            "$name route HAS fondation.csrf condition")
            or diag "requires: " . join(', ', @$reqs);
    }
};

# ── Control: without CSRF plugin, routes have no csrf ───────────────────

subtest 'Without CSRF plugin, routes have no fondation.csrf' => sub {
    my $tmpdir = tempdir(CLEANUP => 1);

    my $app = Mojolicious->new;
    $app->home(Mojo::Home->new($tmpdir));
    $app->log->level('error');
    $app->secrets(['test_secret_32_bytes_minimum']);

    # Load Fondation WITHOUT CSRF plugin
    $app->plugin('Fondation' => {
        dependencies => [
            { 'Fondation::SessionStore' => { store_dir => "$tmpdir/sessions" }},
        ],
    });

    my $spec = {
        openapi => '3.0.3',
        info    => { title => 'NoCSRF Test', version => '1.0' },
        servers => [{ url => '' }],
        paths   => {
            '/items' => {
                post => { operationId => 'create_item', responses => { '201' => { description => 'Created' }}},
            },
        },
    };

    my $spec_file = $app->home->child('share', 'openapi.json');
    $spec_file->dirname->make_path;
    $spec_file->spurt(encode_json($spec));

    $app->routes->post('/items')->name('create_item');

    my $openapi = $app->plugin(OpenAPI => {
        url => $spec_file->to_string,
    });

    my $route = $openapi->route->find('create_item');
    ok $route, 'POST /items route found';
    my $reqs = $route->requires || [];
    ok(!(grep { $_ eq 'fondation.csrf' } @$reqs),
        'POST route does NOT have fondation.csrf without CSRF plugin');
};

done_testing;
