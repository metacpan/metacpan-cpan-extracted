#!/usr/bin/env perl
use Mojo::Base -strict;
use Test::More;
use File::Temp qw(tempdir);
use Test::Mojo;

# ── Test app with CSRF plugin ──────────────────────────────────────────

my $tmpdir = tempdir(CLEANUP => 1);

{
    package CSRFTestApp;
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

        # Helper: returns the current CSRF token (for test extraction)
        $r->get('/token' => sub ($c) {
            $c->render(json => { csrf_token => $c->csrf_token });
        });

        # Route WITH CSRF protection (all mutating methods)
        $r->any('/protected')->requires('fondation.csrf')->to(cb => sub {
            my $c = shift;
            $c->render(json => { ok => 1 });
        });

        # Route WITHOUT CSRF protection (POST)
        $r->post('/unprotected')->to(cb => sub {
            my $c = shift;
            $c->render(json => { ok => 1 });
        });

        # GET route with CSRF condition (should always pass)
        $r->get('/get-ok')->requires('fondation.csrf')->to(cb => sub {
            my $c = shift;
            $c->render(json => { ok => 1 });
        });
    }
}

my $t = Test::Mojo->new('CSRFTestApp');

# ── Tests ──────────────────────────────────────────────────────────────

subtest 'GET route always passes CSRF condition' => sub {
    $t->get_ok('/get-ok')
      ->status_is(200)
      ->json_is('/ok' => 1, 'GET with requires(fondation.csrf) passes');
};

subtest 'POST without any token fails' => sub {
    $t->post_ok('/protected' => form => { foo => 'bar' })
      ->status_is(403)
      ->text_is('.error-code', '403')
      ->text_is('.error-title', 'CSRF token missing or invalid');
};

subtest 'POST without CSRF condition succeeds' => sub {
    $t->post_ok('/unprotected' => form => { foo => 'bar' })
      ->status_is(200)
      ->json_is('/ok' => 1, 'unprotected route works');
};

subtest 'POST with valid csrf_token form field succeeds' => sub {
    my $token = $t->ua->get('/token')->res->json('/csrf_token');
    ok $token, 'got a CSRF token';

    $t->post_ok('/protected' => form => { csrf_token => $token, foo => 'bar' })
      ->status_is(200)
      ->json_is('/ok' => 1, 'POST with valid csrf_token passes');
};

subtest 'POST with wrong csrf_token fails' => sub {
    $t->post_ok('/protected' => form => { csrf_token => 'wrong_token', foo => 'bar' })
      ->status_is(403)
      ->text_is('.error-code', '403')
      ->text_is('.error-title', 'CSRF token missing or invalid');
};

subtest 'POST with X-CSRF-Token header succeeds' => sub {
    my $token = $t->ua->get('/token')->res->json('/csrf_token');

    $t->post_ok('/protected' => {'X-CSRF-Token' => $token} => form => { foo => 'bar' })
      ->status_is(200)
      ->json_is('/ok' => 1, 'POST with X-CSRF-Token header passes');
};

subtest 'POST with wrong X-CSRF-Token header fails' => sub {
    $t->post_ok('/protected' => {'X-CSRF-Token' => 'wrong_header_token'} => form => { foo => 'bar' })
      ->status_is(403)
      ->text_is('.error-code', '403')
      ->text_is('.error-title', 'CSRF token missing or invalid');
};

subtest 'PUT method is also protected' => sub {
    my $token = $t->ua->get('/token')->res->json('/csrf_token');

    # PUT without token
    $t->put_ok('/protected' => form => { foo => 'bar' })
      ->status_is(403);

    # PUT with token
    $t->put_ok('/protected' => {'X-CSRF-Token' => $token} => form => { foo => 'bar' })
      ->status_is(200);
};

subtest 'HEAD and OPTIONS are always allowed' => sub {
    $t->head_ok('/protected')
      ->status_is(200);

    $t->options_ok('/protected')
      ->status_is(200);
};

done_testing;
