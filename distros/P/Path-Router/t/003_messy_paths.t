#!/usr/bin/perl

use strict;
use warnings;

use Test::More 1.001013;
use Test::Path::Router;
#use Data::Dumper;

use Path::Router;

=pod

This test how the router fairs with messy URIs

=cut

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

# run it through some tests

path_ok($router, '/blog/', '... this path is valid');
path_ok($router, './blog/', '... this path is valid');
path_ok($router, '///.///.///blog//.//', '... this path is valid');
path_ok($router, '/blog/./show/.//./20', '... this path is valid');
path_ok($router, '/blog/./2006/.//./20////////10', '... this path is valid');

path_is($router,
    '/blog/',
    {
        controller => 'blog',
        action     => 'index',
    },
'... this path matches the mapping');

path_is($router,
    '///.///.///blog//.//',
    {
        controller => 'blog',
        action     => 'index',
    },
'... this path matches the mapping');

path_is($router,
    '/blog/./show/.//./20',
    {
        controller => 'blog',
        action     => 'show',
        id         => 20,
    },
'... this path matches the mapping');

path_is($router,
    '/blog/./2006/.//./20////////10',
    {
        controller => 'blog',
        action     => 'show_date',
        year       => 2006,
        month      => 20,
        day        => 10,
    },
'... this path matches the mapping');

done_testing;
