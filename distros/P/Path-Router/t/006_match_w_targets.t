#!/usr/bin/perl

use strict;
use warnings;

use Test::More 1.001013;
use Test::Path::Router;

use Path::Router;

for my $inline (0, 1) {
    my $INDEX     = bless {} => 'Blog::Index';
    my $SHOW_DATE = bless {} => 'Blog::ShowDate';
    my $GENERAL   = bless {} => 'Blog::Controller';

    my $router = Path::Router->new(inline => $inline);
    isa_ok($router, 'Path::Router');

# create some routes

    $router->add_route('blog' => (
        defaults       => {
            controller => 'blog',
            action     => 'index',
        },
        target => $INDEX,
    ));

    $router->add_route('blog/:year/:month/:day' => (
        defaults       => {
            controller => 'blog',
            action     => 'show_date',
        },
        validations => {
            year    => qr/\d{4}/,
            month   => qr/\d{1,2}/,
            day     => qr/\d{1,2}/,
        },
        target => $SHOW_DATE,
    ));

    $router->add_route('blog/:action/:id' => (
        defaults       => {
            controller => 'blog',
        },
        validations => {
            action  => qr/\D+/,
            id      => qr/\d+/
        },
        target => $GENERAL
    ));

    my $suffix = '';
    $suffix = ' (inline)' if $inline;

    {
        my $match = $router->match('/blog/');
        isa_ok($match, 'Path::Router::Route::Match');

        is($match->route->target, $INDEX, '... got the right target' . $suffix);
        is_deeply(
            $match->mapping,
            {
                controller => 'blog',
                action     => 'index',
            },
            '... got the right mapping' . $suffix
        );
    }
    {
        my $match = $router->match('/blog/2006/12/1');
        isa_ok($match, 'Path::Router::Route::Match');

        is($match->route->target, $SHOW_DATE, '... got the right target' . $suffix);
        is_deeply(
            $match->mapping,
            {
                controller => 'blog',
                action     => 'show_date',
                year       => 2006,
                month      => 12,
                day        => 1,
            },
            '... got the right mapping' . $suffix
        );
    }
    {
        my $match = $router->match('/blog/show/5');
        isa_ok($match, 'Path::Router::Route::Match');

        is($match->route->target, $GENERAL, '... got the right target' . $suffix);
        is_deeply(
            $match->mapping,
            {
                controller => 'blog',
                action     => 'show',
                id         => 5,
            },
            '... got the right mapping' . $suffix
        );
    }
    {
        my $match = $router->match('/blog/show/0');
        isa_ok($match, 'Path::Router::Route::Match');

        is($match->route->target, $GENERAL, '... got the right target' . $suffix);
        is_deeply(
            $match->mapping,
            {
                controller => 'blog',
                action     => 'show',
                id         => 0,
            },
            '... got the right mapping' . $suffix
        );
    }
}

done_testing;
