#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);
use Test::Mojo;
use Mojolicious::Sessions::Store;
use Mojolicious::Sessions::Store::Backend::File;

my $tmpdir = tempdir(CLEANUP => 1);

{
    package IntegrationApp;
    use Mojo::Base 'Mojolicious', -signatures;

    sub startup ($self) {
        $self->sessions(
            Mojolicious::Sessions::Store->new(
                backend => Mojolicious::Sessions::Store::Backend::File->new(
                    store_dir => "$tmpdir/sessions",
                ),
                cookie_name        => 'testapp',
                default_expiration => 3600,
            )
        );

        my $r = $self->routes;

        $r->get('/set' => sub ($c) {
            $c->session(user_id => 42);
            $c->session(username => 'alice');
            $c->render(text => 'session set');
        });

        $r->get('/read' => sub ($c) {
            my $uid = $c->session('user_id');
            my $un  = $c->session('username');
            $c->render(json => { user_id => $uid, username => $un });
        });

        $r->get('/clear' => sub ($c) {
            $c->session(expires => 1);
            $c->render(text => 'cleared');
        });

        $r->get('/flash_set' => sub ($c) {
            $c->flash(message => 'hello world');
            $c->redirect_to('/flash_read');
        });

        $r->get('/flash_read' => sub ($c) {
            $c->render(json => { flash => $c->flash('message') });
        });
    }
}

my $t = Test::Mojo->new('IntegrationApp');

subtest 'set session via /set, read via /read' => sub {
    $t->get_ok('/set')->status_is(200)->content_is('session set');
    $t->get_ok('/read')->status_is(200)
        ->json_is('/user_id', 42)
        ->json_is('/username', 'alice');
};

subtest 'session persists across requests' => sub {
    $t->get_ok('/read')->status_is(200)
        ->json_is('/user_id', 42);
};

subtest 'clear session' => sub {
    $t->get_ok('/clear')->status_is(200);
    $t->get_ok('/read')->status_is(200)
        ->json_is('/user_id', undef)
        ->json_is('/username', undef);
};

subtest 'flash data works across redirect' => sub {
    $t->get_ok('/flash_set')->status_is(302);

    # Follow the redirect — flash should be available
    $t->get_ok('/flash_read')->status_is(200)
        ->json_is('/flash', 'hello world');

    # Flash consumed after one read
    $t->get_ok('/flash_read')->status_is(200)
        ->json_is('/flash', undef);
};

subtest 'session files are created' => sub {
    $t->get_ok('/set')->status_is(200);
    my @files = glob("$tmpdir/sessions/*.json");
    cmp_ok scalar(@files), '>', 0, 'session files exist on disk';
};

done_testing;
