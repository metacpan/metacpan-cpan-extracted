#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use Test::Mojo;
use Mojo::Base -signatures;
use FindBin;
use lib "$FindBin::Bin/../lib", "$FindBin::Bin/lib";
use File::Temp qw(tempdir);
use Mojolicious::Plugin::Fondation::TestHelper qw(create_test_app);
use Digest::SHA qw(sha256_hex);
use Mojo::JSON qw(true false);

my $tmpdir = tempdir(CLEANUP => 1);
my $dbfile = "$tmpdir/test.db";

# -- Build app ------------------------------------------------------

my $app = create_test_app($tmpdir);
$app->plugin('Fondation' => {
    dependencies => [
        { 'Fondation::Model::DBIx::Async' => {
            backends => [
                main => {
                    dsn          => "dbi:SQLite:dbname=$dbfile",
                    schema_class => 'TestTokenSchema',
                    workers      => 1,
                    quote_char   => '"',
                },
            ],
        }},
        'Fondation::Auth',
        'Fondation::Auth::Token',
    ],
});

my $c = $app->build_controller;

# -- Deploy schema ---------------------------------------------------

my $schema = $c->schema;
$schema->await($schema->deploy);

# -- Create test user (admin, id=1) ---------------------------------

my $user = $schema->await(
    $c->model('user')->create({
        username => 'admin',
        password => 'pass',
        email    => 'admin@example.com',
        active   => 1,
    })
);
ok($user->id, 'Test user created');
is($user->id, 1, 'User id is 1');

# -- Create test API token ------------------------------------------

my $raw_token = 'test-token-admin-00000000000000';
my $token = $schema->await(
    $c->model('api_token')->create({
        user_id    => $user->id,
        token_hash => sha256_hex($raw_token),
        name       => 'Test admin token',
    })
);
ok($token->id, 'API token created');

# -- Test client ----------------------------------------------------

my $t = Test::Mojo->new($app);
$t->app->log->level('error');


# -- Routes ---------------------------------------------------------
#
# /public         --  no fondation.bearer, always 200
# /api/secure     --  requires fondation.bearer
# /api/status     --  requires fondation.bearer, returns auth status

my $r = $app->routes;

$r->get('/public')->to(cb => sub ($c) {
    $c->render(json => {
        authenticated => $c->is_user_authenticated ? true : false,
    });
});

$r->get('/api/secure')->requires('fondation.bearer')->to(cb => sub ($c) {
    $c->render(json => { ok => true });
});

$r->get('/api/status')->requires('fondation.bearer')->to(cb => sub ($c) {
    $c->render(json => {
        authenticated => $c->is_user_authenticated ? true : false,
    });
});

# ======================================================================
#  Routes WITHOUT fondation.bearer  --  Bearer is silently ignored
# ======================================================================

subtest 'Public route - no auth' => sub {
    $t->get_ok('/public')
      ->status_is(200)
      ->json_is('/authenticated' => false, 'Not authenticated');
};

subtest 'Public route  --  valid Bearer rejected 403' => sub {
    $t->get_ok('/public' => { Authorization => "Bearer $raw_token" })
      ->status_is(403, 'Bearer rejected on route without fondation.bearer');
};

subtest 'Public route  --  invalid Bearer' => sub {
    $t->get_ok('/public' => { Authorization => 'Bearer deadbeef-deadbeef-deadbeef' })
      ->status_is(200)
      ->json_is('/authenticated' => false, 'Invalid Bearer ignored');
};

# ======================================================================
#  Routes WITH fondation.bearer  --  enforcement active
# ======================================================================

subtest 'Bearer route  --  no auth -> 401' => sub {
    $t->get_ok('/api/secure')
      ->status_is(401, 'Authentication required');
};

subtest 'Bearer route  --  valid Bearer -> 200' => sub {
    $t->get_ok('/api/secure' => { Authorization => "Bearer $raw_token" })
      ->status_is(200)
      ->json_is('/ok' => true, 'Access granted');
};

subtest 'Bearer route  --  invalid Bearer -> 403' => sub {
    $t->get_ok('/api/secure' => { Authorization => 'Bearer deadbeef-deadbeef-deadbeef' })
      ->status_is(403, 'Invalid bearer token');
};

subtest 'Bearer route  --  cookie auth works too' => sub {
    # Login via cookie
    $t->post_ok('/login' => form => { username => 'admin', password => 'pass' })
      ->status_is(302, 'Login redirects');

    # Access bearer-protected route with cookie (no Bearer header)
    $t->get_ok('/api/status')
      ->status_is(200)
      ->json_is('/authenticated' => true, 'Authenticated via cookie');
};

subtest 'Bearer route  --  second request with same token' => sub {
    $t->ua->cookie_jar->empty;
    $t->get_ok('/api/status' => { Authorization => "Bearer $raw_token" })
      ->status_is(200)
      ->json_is('/authenticated' => true, 'Still authenticated');
};

done_testing;
