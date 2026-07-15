#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use Test::Mojo;

# ── Test app ─────────────────────────────────────────────────────
{
    package ProblemTestApp;
    use Mojo::Base 'Mojolicious', -signatures;

    sub startup ($self) {
        $self->secrets(['test_secret_32_bytes_minimum']);

        $self->plugin('Fondation' => {
            dependencies => ['Fondation::Problem'],
        });

        $self->routes->get('/html/error')->to(cb => sub {
            my $c = shift;
            $c->problem(
                status => 403,
                title  => 'Access denied',
                detail => 'Missing permission: user_create',
            );
        });

        $self->routes->get('/html/defaults')->to(cb => sub {
            my $c = shift;
            $c->problem();
        });
    }
}

my $t = Test::Mojo->new('ProblemTestApp');

# ── HTML: full details in development ────────────────────────────
subtest 'HTML: full details in development' => sub {
    $t->app->mode('development');
    $t->get_ok('/html/error')
      ->status_is(403)
      ->content_type_like(qr{text/html})
      ->text_is('.error-code', '403', 'status code')
      ->text_is('.error-title', 'Access denied', 'title')
      ->content_like(qr/Missing permission/, 'detail visible in dev');
};

# ── HTML: minimal details in production ──────────────────────────
subtest 'HTML: detail hidden in production' => sub {
    $t->app->mode('production');
    $t->get_ok('/html/error')
      ->status_is(403)
      ->content_type_like(qr{text/html})
      ->text_is('.error-code', '403', 'status code')
      ->text_is('.error-title', 'Access denied', 'title')
      ->content_unlike(qr/Missing permission/, 'detail hidden in prod');
};

# ── HTML: default values ─────────────────────────────────────────
subtest 'HTML: default values when no args' => sub {
    $t->app->mode('development');
    $t->get_ok('/html/defaults')
      ->status_is(500)
      ->content_type_like(qr{text/html})
      ->text_is('.error-code', '500', 'default status 500')
      ->text_is('.error-title', 'Internal Server Error', 'default title');
};

# ── HTML: format is html not json ────────────────────────────────
subtest 'HTML: does not return JSON content-type' => sub {
    $t->app->mode('development');
    $t->get_ok('/html/error')
      ->content_type_like(qr{text/html})
      ->header_isnt('Content-Type' => qr{problem\+json});
};

# ── HTML: Go Home link ───────────────────────────────────────────
subtest 'HTML: contains Go Home link' => sub {
    $t->app->mode('development');
    $t->get_ok('/html/error')
      ->text_is('.home-link', 'Go Home');
};

# ── HTML: color class for 4xx vs 5xx ─────────────────────────────
subtest 'HTML: color for 4xx errors' => sub {
    $t->app->mode('development');
    $t->get_ok('/html/error')
      ->content_like(qr/#f59e0b/, 'amber for 403');
};

subtest 'HTML: color for 5xx errors' => sub {
    $t->get_ok('/html/defaults')
      ->content_like(qr/#ef4444/, 'red for 500');
};

done_testing;
