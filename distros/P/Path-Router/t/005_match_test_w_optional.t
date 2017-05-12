#!/usr/bin/perl

use strict;
use warnings;

use Test::More 1.001013;
use Test::Path::Router;

use Path::Router;

my $router = Path::Router->new;
isa_ok($router, 'Path::Router');

# create some routes

$router->add_route(':controller/?:action' => (
    defaults   => {
        action => 'index'
    },
    validations => {
        controller => qr/\D+/,
        action     => qr/\D+/
    }
));

$router->add_route(':controller/:id/?:action' => (
    defaults   => {
        action => 'show',
    },
    validations => {
        controller => qr/\D+/,
        action     => qr/\D+/,
        id         => qr/\d+/,
    }
));


path_ok($router, $_, '... matched path (' . $_ . ')')
    foreach qw[
        /users/

        /users/new/

        /users/10/
        /users/100000000000101010101/

        /users/10/edit/
        /users/1/show/
        /users/100000000000101010101/show
    ];

path_not_ok($router, $_, '... could not match path (' . $_ . ')')
    foreach qw[
        /10/

        /20/10/

        /users/10/12/

        /users/edit/12/
    ];

done_testing;
