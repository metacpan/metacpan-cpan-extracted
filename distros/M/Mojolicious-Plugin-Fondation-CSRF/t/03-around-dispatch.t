#!/usr/bin/env perl
use Mojo::Base -strict;
use Test::More;
use File::Temp qw(tempdir);
use Test::Mojo;

# ── Test 1: auto_protect => 1 (default) ────────────────────────────────

{
    my $tmpdir = tempdir(CLEANUP => 1);

    package AutoProtectApp;
    use Mojo::Base 'Mojolicious', -signatures;

    sub startup ($self) {
        $self->home(Mojo::Home->new($tmpdir));
        $self->secrets(['test_secret_32_bytes_minimum']);

        $self->plugin('Fondation' => {
            dependencies => [
                { 'Fondation::SessionStore' => { store_dir => "$tmpdir/sessions" }},
                { 'Fondation::CSRF' => { auto_protect => 1 }},
            ],
        });

        my $r = $self->routes;

        # Helper: returns the CSRF token
        $r->get('/token' => sub ($c) {
            $c->render(json => { csrf_token => $c->csrf_token });
        });

        # POST route — no explicit csrf condition, but auto_protect covers it
        $r->post('/submit' => sub ($c) {
            $c->render(json => { ok => 1 });
        });

        # GET route — never blocked
        $r->get('/page' => sub ($c) {
            $c->render(json => { ok => 1 });
        });
    }
}

my $t = Test::Mojo->new('AutoProtectApp');

subtest 'GET routes are never blocked by around_dispatch' => sub {
    $t->get_ok('/page')
      ->status_is(200)
      ->json_is('/ok' => 1);
};

subtest 'POST without token is blocked by around_dispatch' => sub {
    $t->post_ok('/submit' => form => { foo => 'bar' })
      ->status_is(403)
      ->text_is('.error-code', '403')
      ->text_is('.error-title', 'CSRF token missing or invalid');
};

subtest 'POST with valid token passes around_dispatch' => sub {
    my $token = $t->ua->get('/token')->res->json('/csrf_token');

    $t->post_ok('/submit' => form => { csrf_token => $token, foo => 'bar' })
      ->status_is(200)
      ->json_is('/ok' => 1);
};

subtest 'POST with X-CSRF-Token header passes around_dispatch' => sub {
    my $token = $t->ua->get('/token')->res->json('/csrf_token');

    $t->post_ok('/submit' => {'X-CSRF-Token' => $token} => form => { foo => 'bar' })
      ->status_is(200)
      ->json_is('/ok' => 1);
};

# ── Test 2: auto_protect => 0 (disabled) ────────────────────────────────

{
    my $tmpdir = tempdir(CLEANUP => 1);

    package NoAutoProtectApp;
    use Mojo::Base 'Mojolicious', -signatures;

    sub startup ($self) {
        $self->home(Mojo::Home->new($tmpdir));
        $self->secrets(['test_secret_32_bytes_minimum']);

        $self->plugin('Fondation' => {
            dependencies => [
                { 'Fondation::SessionStore' => { store_dir => "$tmpdir/sessions" }},
                { 'Fondation::CSRF' => { auto_protect => 0 }},
            ],
        });

        my $r = $self->routes;

        $r->post('/submit' => sub ($c) {
            $c->render(json => { ok => 1 });
        });
    }
}

my $t2 = Test::Mojo->new('NoAutoProtectApp');

subtest 'auto_protect => 0: POST without token succeeds' => sub {
    $t2->post_ok('/submit' => form => { foo => 'bar' })
       ->status_is(200)
       ->json_is('/ok' => 1, 'no CSRF check when auto_protect is off');
};

# ── Test 3: auto_protect with exemptions ────────────────────────────────

{
    my $tmpdir = tempdir(CLEANUP => 1);

    package ExemptApp;
    use Mojo::Base 'Mojolicious', -signatures;

    sub startup ($self) {
        $self->home(Mojo::Home->new($tmpdir));
        $self->secrets(['test_secret_32_bytes_minimum']);

        $self->plugin('Fondation' => {
            dependencies => [
                { 'Fondation::SessionStore' => { store_dir => "$tmpdir/sessions" }},
                { 'Fondation::CSRF' => {
                    auto_protect => 1,
                    exemptions   => [qr{^/webhook/}, qr{^/api/public/}],
                }},
            ],
        });

        my $r = $self->routes;

        $r->post('/webhook/github' => sub ($c) {
            $c->render(json => { ok => 1 });
        });

        $r->post('/api/public/status' => sub ($c) {
            $c->render(json => { ok => 1 });
        });

        $r->post('/api/private/action' => sub ($c) {
            $c->render(json => { ok => 1 });
        });
    }
}

my $t3 = Test::Mojo->new('ExemptApp');

subtest 'Exempted paths skip CSRF' => sub {
    $t3->post_ok('/webhook/github' => form => { payload => 'test' })
       ->status_is(200)
       ->json_is('/ok' => 1, 'webhook exempted');

    $t3->post_ok('/api/public/status' => form => {})
       ->status_is(200)
       ->json_is('/ok' => 1, 'public API exempted');
};

subtest 'Non-exempted paths are still protected' => sub {
    $t3->post_ok('/api/private/action' => form => { action => 'test' })
       ->status_is(403, 'private API not exempted');
};

done_testing;
