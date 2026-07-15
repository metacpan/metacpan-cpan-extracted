#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);
use Test::Mojo;

my $tmpdir = tempdir(CLEANUP => 1);
my $store_dir = "$tmpdir/sessions";

# ── Test app using Fondation ────────────────────────────────────────────

{
    package SessionStoreTestApp;
    use Mojo::Base 'Mojolicious', -signatures;

    sub startup ($self) {
        $self->home(Mojo::Home->new($tmpdir));

        # Must set secrets for signed cookies
        $self->secrets(['test_secret_32_bytes_minimum']);

        # Load Fondation with the SessionStore plugin
        $self->plugin('Fondation' => {
            dependencies => [
                { 'Fondation::SessionStore' => {
                    backend   => 'file',
                    store_dir => $store_dir,
                    session   => {
                        cookie_name        => 'testsess',
                        default_expiration => 3600,
                    },
                }},
            ],
        });

        # Test routes
        my $r = $self->routes;

        $r->get('/set' => sub ($c) {
            $c->session(user_id => 99);
            $c->session(username => 'testuser');
            $c->render(text => 'ok');
        });

        $r->get('/read' => sub ($c) {
            $c->render(json => {
                user_id  => $c->session('user_id'),
                username => $c->session('username'),
            });
        });

        $r->get('/clear' => sub ($c) {
            $c->session(expires => 1);
            $c->render(text => 'cleared');
        });
    }
}

my $t = Test::Mojo->new('SessionStoreTestApp');

# ── Tests ───────────────────────────────────────────────────────────────

subtest 'sessions object is our Store' => sub {
    my $s = $t->app->sessions;
    isa_ok $s, 'Mojolicious::Sessions::Store';
    is $s->cookie_name, 'testsess', 'cookie_name from config';
    is $s->default_expiration, 3600, 'default_expiration from config';
};

subtest 'backend is File' => sub {
    my $s = $t->app->sessions;
    isa_ok $s->backend, 'Mojolicious::Sessions::Store::Backend::File';
    is $s->backend->store_dir, $store_dir, 'store_dir matches config';
};

subtest 'set and read session' => sub {
    $t->get_ok('/set')->status_is(200);
    $t->get_ok('/read')->status_is(200)
        ->json_is('/user_id', 99)
        ->json_is('/username', 'testuser');
};

subtest 'session persists across requests' => sub {
    $t->get_ok('/read')->status_is(200)->json_is('/user_id', 99);
};

subtest 'clear session' => sub {
    $t->get_ok('/set')->status_is(200);
    $t->get_ok('/clear')->status_is(200);
    $t->get_ok('/read')->status_is(200)
        ->json_is('/user_id', undef)
        ->json_is('/username', undef);
};

subtest 'session files are created' => sub {
    $t->get_ok('/set')->status_is(200);
    my @files = glob("$store_dir/*.json");
    cmp_ok scalar(@files), '>', 0, 'session files exist on disk';
};

done_testing;
