#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use Mojo::File 'path';
use Mojo::JSON qw(encode_json true);
use Test::Mojo;
use File::Temp 'tempdir';
use FindBin;
use lib "$FindBin::Bin/../lib";
use lib "$FindBin::Bin/lib";
use lib "$FindBin::Bin/../../Mojolicious-Plugin-Fondation/lib";

use Mojolicious::Plugin::Fondation::TestHelper qw(create_test_app);

# ==========================================================================
# Regression: route conditions must NOT render during the route tree walk.
#
# Mojo evaluates route conditions DURING the walk, before knowing whether
# the route fully matches: patterns are anchored at the start only, so a
# list route (/api/foo) also prefix-matches /api/foo/:id and its condition
# is evaluated for that request. A condition that renders a response is
# therefore evaluated twice in a single request — the second render dies
# with "A response has already been rendered" and kills the worker.
#
# Fix: failed conditions set the 'fondation.denied' stash marker; the
# Fondation around_dispatch hook renders it once, after the walk.
# ==========================================================================

{
    my $tmpdir = tempdir(CLEANUP => 1);
    my $dbfile = "$tmpdir/test.db";
    my $app    = create_test_app($tmpdir);

    # Hand-written spec: list route + {id} route, both x-auth protected
    my $spec_dir = $app->home->child('share');
    $spec_dir->make_path;
    $spec_dir->child('openapi.json')->spurt(encode_json({
        openapi => '3.0.3',
        info    => { title => 'Test', version => '1.0' },
        servers => [{ url => '/api' }],
        paths   => {
            '/foo' => {
                get => {
                    operationId => 'list_foo',
                    responses   => { 200 => { description => 'Success' } },
                    'x-auth'    => { permissions => ['foo_list'] },
                    'x-mojo-to' => 'Foo#list',
                },
            },
            '/foo/{id}' => {
                get => {
                    operationId => 'read_foo',
                    parameters  => [{
                        in     => 'path',
                        name   => 'id',
                        required => true,
                        schema => { type => 'integer' },
                    }],
                    responses   => { 200 => { description => 'Success' } },
                    'x-auth'    => { permissions => ['foo_read'] },
                    'x-mojo-to' => 'Foo#read',
                },
            },
        },
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

    # Simulate an unauthenticated user without any permission
    $app->helper(check_perm => sub { 0 });

    my $t = Test::Mojo->new($app);

    $t->get_ok('/api/foo/1')->status_is(403,
        'unauthenticated {id} route -> clean 403, no double-render crash');
    $t->get_ok('/api/foo/1')->status_is(403,
        'second call still works (worker alive)');
    $t->get_ok('/api/foo')->status_is(403,
        'unauthenticated list route -> clean 403');
}

done_testing;
