#!/usr/bin/perl

use strict;
use warnings;

use Test::More 1.001013;
use Test::Path::Router;

use Path::Router;

my $router = Path::Router->new;
isa_ok($router, 'Path::Router');

# create some routes

$router->add_route('blog' => (
    defaults       => {
        controller => 'blog',
        action     => 'index',
    }
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
    }
));

$router->add_route('blog/:action/:id' => (
    defaults       => {
        controller => 'blog',
    },
    validations => {
        action  => qr/\D+/,
        id      => qr/\d+/
    }
));

path_ok($router, $_, '... matched path (' . $_ . ')')
    foreach qw[
        /blog/

        /blog/edit/15/

        /blog/2006/31/20/
        /blog/2006/31/2/
        /blog/2006/3/2/
        /blog/2006/3/20/
    ];

path_not_ok($router, $_, '... could not match path (' . $_ . ')')
    foreach qw[
        foo/
        /foo

        /blog/index
        /blog/foo
        /blog/foo/bar
        /blog/10/bar
        blog/10/1000

        /blog/show_date/2006/31/2
        /blog/06/31/2
        /blog/20063/31/2
        /blog/2006/31/200
        /blog/2006/310/1
    ];

done_testing;
