#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use Test::Mojo;
use Mojolicious::Sessions::Store;

# ── In-memory backend for testing ───────────────────────────────────────

BEGIN {
    package TestBackend;
    use Mojo::Base -base, -signatures;

    has 'data'    => sub { {} };
    has 'deleted' => sub { [] };
    has 'saved'   => sub { [] };

    sub load ($self, $id)   { return $self->data->{$id} }
    sub save ($self, $id, $data) {
        $self->data->{$id} = { %$data };
        push @{$self->saved}, $id;
        return 1;
    }
    sub delete ($self, $id) {
        delete $self->data->{$id};
        push @{$self->deleted}, $id;
        return 1;
    }
}

# ── Test app ────────────────────────────────────────────────────────────

{
    package TestApp;
    use Mojo::Base 'Mojolicious', -signatures;

    sub startup ($self) {
        $self->sessions(
            Mojolicious::Sessions::Store->new(
                backend           => $TestBackend::instance,
                cookie_name        => 'testapp',
                default_expiration => 3600,
            )
        );

        my $r = $self->routes;

        $r->get('/set' => sub ($c) {
            $c->session(user_id => 99);
            $c->session(username => 'bob');
            $c->render(text => 'ok');
        });

        $r->get('/read' => sub ($c) {
            $c->render(json => {
                user_id  => $c->session('user_id'),
                username => $c->session('username'),
            });
        });

        $r->get('/update' => sub ($c) {
            $c->session(counter => 2);
            $c->render(text => 'updated');
        });

        $r->get('/clear' => sub ($c) {
            $c->session(expires => 1);
            $c->render(text => 'cleared');
        });

        $r->get('/flash_set' => sub ($c) {
            $c->flash(msg => 'hello');
            $c->redirect_to('/flash_read');
        });

        $r->get('/flash_read' => sub ($c) {
            $c->render(json => { flash => $c->flash('msg') });
        });
    }
}

my $backend = TestBackend->new;
$TestBackend::instance = $backend;

my $t = Test::Mojo->new('TestApp');

# ── Tests ───────────────────────────────────────────────────────────────

subtest 'constructor' => sub {
    my $s = $t->app->sessions;
    isa_ok $s, 'Mojolicious::Sessions::Store';
    is $s->cookie_name, 'testapp', 'cookie_name';
    is $s->default_expiration, 3600, 'default_expiration';
};

subtest 'set and read session' => sub {
    $t->get_ok('/set')->status_is(200);
    $t->get_ok('/read')->status_is(200)
        ->json_is('/user_id', 99)
        ->json_is('/username', 'bob');
};

subtest 'session persists across requests' => sub {
    $t->get_ok('/read')->status_is(200)->json_is('/user_id', 99);
};

subtest 'update existing session' => sub {
    $t->get_ok('/set')->status_is(200);
    my $session_id = (keys %{$backend->data})[0];
    ok $session_id, 'session exists in backend';

    $t->get_ok('/update')->status_is(200);

    my $updated = $backend->load($session_id);
    ok $updated, 'session still exists';
    is $updated->{counter}, 2, 'counter updated';
};

subtest 'clear session (logout)' => sub {
    $t->get_ok('/set')->status_is(200);
    my $session_id = (keys %{$backend->data})[0];
    ok $session_id, 'session exists';

    $t->get_ok('/clear')->status_is(200);
    is $backend->load($session_id), undef, 'session removed from backend';
};

subtest 'flash data across redirect' => sub {
    $t->get_ok('/flash_set')->status_is(302);

    # Follow the redirect manually — flash should be available
    $t->get_ok('/flash_read')->status_is(200)
        ->json_is('/flash', 'hello');

    # Flash should be consumed after one read
    $t->get_ok('/flash_read')->status_is(200)
        ->json_is('/flash', undef);
};

subtest 'session_id is 64 hex chars' => sub {
    $t->get_ok('/set')->status_is(200);
    my $sid = (keys %{$backend->data})[0];
    like $sid, qr/^[0-9a-f]{64}$/, 'session_id is 64 hex chars';
};

subtest 'backend save is called' => sub {
    my $before = scalar @{$backend->saved};
    $t->get_ok('/set')->status_is(200);
    cmp_ok scalar(@{$backend->saved}), '>', $before, 'backend save called';
};

subtest 'backend delete is called on clear' => sub {
    $t->get_ok('/set')->status_is(200);
    my $before = scalar @{$backend->deleted};
    $t->get_ok('/clear')->status_is(200);
    cmp_ok scalar(@{$backend->deleted}), '>', $before, 'backend delete called';
};

done_testing;
