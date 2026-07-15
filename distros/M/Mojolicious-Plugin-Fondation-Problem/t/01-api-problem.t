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

        # API route with all fields
        $self->routes->get('/api/validation-error')->to(cb => sub {
            my $c = shift;
            push @{$c->match->stack}, {'openapi.path' => '/api/validation-error'};
            $c->problem(
                status   => 422,
                title    => 'Validation failed',
                detail   => 'Field "name" is too long (60 > 50)',
                type     => '/problem/validation',
                errors   => [
                    { detail => 'String too long', pointer => '/name' },
                ],
                instance => '/logs/abc-123',
            );
        });

        # API route with minimal args
        $self->routes->get('/api/minimal')->to(cb => sub {
            my $c = shift;
            push @{$c->match->stack}, {'openapi.path' => '/api/minimal'};
            $c->problem();
        });

        # API route with only status + title
        $self->routes->get('/api/basic')->to(cb => sub {
            my $c = shift;
            push @{$c->match->stack}, {'openapi.path' => '/api/basic'};
            $c->problem(status => 403, title => 'Forbidden');
        });
    }
}

my $t = Test::Mojo->new('ProblemTestApp');

# ── API: full details in development ─────────────────────────────
subtest 'API: full RFC 9457 response in development' => sub {
    $t->app->mode('development');
    $t->get_ok('/api/validation-error')
      ->status_is(422)
      ->header_like('Content-Type' => qr{application/problem\+json});

    my $json = $t->tx->res->json;
    is $json->{status},   422, 'status';
    is $json->{title},    'Validation failed', 'title';
    is $json->{detail},   'Field "name" is too long (60 > 50)', 'detail';
    is $json->{type},     '/problem/validation', 'type';
    is $json->{instance}, '/logs/abc-123', 'instance';
    is_deeply $json->{errors}, [
        { detail => 'String too long', pointer => '/name' },
    ], 'errors array with detail + pointer';
};

# ── API: minimal details in production ───────────────────────────
subtest 'API: only status+title in production' => sub {
    $t->app->mode('production');
    $t->get_ok('/api/validation-error')
      ->status_is(422)
      ->header_like('Content-Type' => qr{application/problem\+json});

    my $json = $t->tx->res->json;
    is $json->{status}, 422, 'status present';
    is $json->{title},  'Validation failed', 'title present';
    ok !exists $json->{detail},   'detail absent in prod';
    ok !exists $json->{type},     'type absent in prod';
    ok !exists $json->{errors},   'errors absent in prod';
    ok !exists $json->{instance}, 'instance absent in prod';
};

# ── API: defaults ────────────────────────────────────────────────
subtest 'API: default values when no args' => sub {
    $t->app->mode('development');
    $t->get_ok('/api/minimal')
      ->status_is(500)
      ->header_like('Content-Type' => qr{application/problem\+json});

    my $json = $t->tx->res->json;
    is $json->{status}, 500, 'default status 500';
    is $json->{title},  'Internal Server Error', 'default title';
};

# ── API: basic error in production ───────────────────────────────
subtest 'API: basic error production format' => sub {
    $t->app->mode('production');
    $t->get_ok('/api/basic')
      ->status_is(403)
      ->header_like('Content-Type' => qr{application/problem\+json});

    my $json = $t->tx->res->json;
    is $json->{status}, 403, 'status 403';
    is $json->{title},  'Forbidden', 'title';
    # Only status and title should exist
    is scalar keys %$json, 2, 'only status + title in prod';
};

# ── Format validation: Content-Type must be exact ────────────────
subtest 'API: Content-Type is application/problem+json' => sub {
    $t->app->mode('development');
    $t->get_ok('/api/validation-error')
      ->header_is('Content-Type' => 'application/problem+json');
};

done_testing;
