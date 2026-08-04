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

my $c   = $app->build_controller;
my $schema = $c->schema;
$schema->await($schema->deploy);

# -- Create test users ----------------------------------------------

my $user1 = $schema->await(
    $c->model('user')->create({
        username => 'alice',
        password => 'pass1',
        email    => 'alice@test.local',
        active   => 1,
    })
);
ok($user1->id, 'User 1 created');

my $user2 = $schema->await(
    $c->model('user')->create({
        username => 'bob',
        password => 'pass2',
        email    => 'bob@test.local',
        active   => 1,
    })
);
ok($user2->id, 'User 2 created');

my $t = Test::Mojo->new($app);
$t->app->log->level('error');

# ======================================================================
#  Unauthenticated — rejected
# ======================================================================

subtest 'Unauthenticated access rejected' => sub {
    $t->get_ok('/api/ApiToken')
      ->status_is(401, 'GET /api/ApiToken requires auth');

    $t->post_ok('/api/token/generate' => json => { name => 'test' })
      ->status_is(401, 'POST /api/token/generate requires auth');
};

# ======================================================================
#  Authenticated (Alice) — generate + list + delete
# ======================================================================

# Login as alice
$t->post_ok('/login' => form => { username => 'alice', password => 'pass1' })
  ->status_is(302, 'Alice login redirects');

subtest 'Generate token' => sub {
    $t->post_ok('/api/token/generate' => json => { name => 'my script' })
      ->status_is(201)
      ->json_has('/raw_token', 'raw_token is returned')
      ->json_is('/name' => 'my script')
      ->json_has('/id');

    my $raw = $t->tx->res->json->{raw_token};
    ok(length($raw) == 64, 'Raw token is 64 hex chars');
};

subtest 'List own tokens' => sub {
    $t->get_ok('/api/ApiToken')
      ->status_is(200);

    my $tokens = $t->tx->res->json;
    ok(@$tokens >= 1, 'At least one token');
    # token_hash must NOT be present (writeOnly)
    ok(!exists $tokens->[0]{token_hash}, 'token_hash is writeOnly');
};

subtest 'Revoke token' => sub {
    # Get token id
    $t->get_ok('/api/ApiToken')->status_is(200);
    my $tokens = $t->tx->res->json;
    my $id = $tokens->[0]{id};
    ok($id, "Token id=$id exists");

    $t->delete_ok("/api/ApiToken/$id")
      ->status_is(204, 'Token deleted');

    # Verify gone
    $t->get_ok('/api/ApiToken')->status_is(200);
    my $after = $t->tx->res->json;
    is(@$after, 0, 'No tokens remaining');
};

# ======================================================================
#  User isolation — Alice cannot see Bob's tokens
# ======================================================================

subtest 'User isolation' => sub {
    # Bob: separate client
    my $tb = Test::Mojo->new($app);
    $tb->app->log->level('error');
    $tb->post_ok('/login' => form => { username => 'bob', password => 'pass2' })
      ->status_is(302);

    # Bob creates a token
    $tb->post_ok('/api/token/generate' => json => { name => 'bob token' })
      ->status_is(201);

    # Bob sees his token
    $tb->get_ok('/api/ApiToken')->status_is(200);
    my $bob_tokens = $tb->tx->res->json;
    is(@$bob_tokens, 1, 'Bob sees 1 token');

    # Alice (original client) should NOT see Bob's token
    $t->get_ok('/api/ApiToken')->status_is(200);
    my $alice_tokens = $t->tx->res->json;
    is(@$alice_tokens, 0, 'Alice does not see Bob tokens');
};

done_testing;
