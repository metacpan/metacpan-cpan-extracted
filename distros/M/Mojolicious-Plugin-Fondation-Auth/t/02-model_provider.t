#!/usr/bin/env perl
use Mojo::Base -strict;
use Test::More;
use Test::Mojo;
use FindBin;

use lib "$FindBin::Bin/lib";
use lib "$FindBin::Bin/../lib";
use lib "$FindBin::Bin/../../Mojolicious-Plugin-Fondation-Model-DBIx-Async/lib";

# ─── Create app ──────────────────────────────────────────────────────────────

my $t = Test::Mojo->new('MyApp');
$t->app->log->level('error');

# ─── 1. Public route (no auth required) ──────────────────────────────────────

subtest 'Public route' => sub {
    $t->get_ok('/public')
      ->status_is(200)
      ->content_is('public content', 'Public route accessible without auth');
};

# ─── 2. Protected route without authentication ───────────────────────────────

subtest 'Protected route without authentication' => sub {
    $t->get_ok('/protected')
      ->status_is(403)
      ->content_is('Access denied', 'Protected route denies access');
};

# ─── 3. Login with correct credentials ───────────────────────────────────────

subtest 'Login with correct credentials' => sub {
    $t->post_ok('/login' => form => { username => 'test', password => 'pass' })
      ->status_is(302, 'Login redirects on success')
      ->header_like(Location => qr{/$}, 'Redirects to /');
};

# ─── 4. Login with wrong password ────────────────────────────────────────────

subtest 'Login with wrong password' => sub {
    $t->ua->cookie_jar->empty;
    $t->post_ok('/login' => form => { username => 'test', password => 'wrong' })
      ->status_is(302, 'Login redirects on failure')
      ->header_like(Location => qr{/login}, 'Redirects back to /login');
};

# ─── 5. Login with non-existent user ─────────────────────────────────────────

subtest 'Login with non-existent user' => sub {
    $t->ua->cookie_jar->empty;
    $t->post_ok('/login' => form => { username => 'nonexistent', password => 'pass' })
      ->status_is(302, 'Login redirects on failure')
      ->header_like(Location => qr{/login}, 'Redirects back to /login');
};

# ─── 6. Protected route after authentication ─────────────────────────────────

subtest 'Protected route after authentication' => sub {
    $t->ua->cookie_jar->empty;

    $t->post_ok('/login' => form => { username => 'test', password => 'pass' })
      ->status_is(302);

    $t->get_ok('/protected')
      ->status_is(200)
      ->content_is('Protected content', 'Protected route accessible after login');

    $t->get_ok('/public')
      ->status_is(200)
      ->content_is('public content', 'Public route still accessible after login');
};

# ─── 7. Logout ───────────────────────────────────────────────────────────────

subtest 'Logout' => sub {
    $t->ua->cookie_jar->empty;

    # Login first
    $t->post_ok('/login' => form => { username => 'test', password => 'pass' })
      ->status_is(302);

    # Verify access
    $t->get_ok('/protected')->status_is(200);

    # Logout
    $t->get_ok('/logout')
      ->status_is(302, 'Logout redirects')
      ->header_like(Location => qr{/$}, 'Redirects to /');

    # Protected route inaccessible after logout
    $t->get_ok('/protected')
      ->status_is(403)
      ->content_is('Access denied', 'Protected route denied after logout');

    # Public route still accessible
    $t->get_ok('/public')
      ->status_is(200)
      ->content_is('public content', 'Public route still accessible after logout');
};

# ─── 8. Session persistence across requests ──────────────────────────────────

subtest 'Session persistence' => sub {
    $t->ua->cookie_jar->empty;

    # Login
    $t->post_ok('/login' => form => { username => 'test', password => 'pass' })
      ->status_is(302);

    # Multiple requests without re-login
    for my $i (1 .. 3) {
        $t->get_ok('/protected')
          ->status_is(200)
          ->content_is('Protected content', "Protected route accessible (request $i)");
    }

    # Logout
    $t->get_ok('/logout')->status_is(302);

    # No longer accessible
    $t->get_ok('/protected')->status_is(403);
};

done_testing;
