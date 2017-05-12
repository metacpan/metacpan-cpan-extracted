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
        action  => qr/\D+/
    }
));

$router->add_route(':controller/:id/?:action' => (
    defaults   => {
        action => 'show',
    },
    validations => {
        id      => 'Int',
    }
));

# run it through some tests

routes_ok($router, {
    'people' => {
        controller => 'people',
        action     => 'index',
    },
    'people/new' => {
        controller => 'people',
        action     => 'new',
    },
    'people/create' => {
        controller => 'people',
        action     => 'create',
    },
    'people/56' => {
        controller => 'people',
        action     => 'show',
        id         => 56,
    },
    'people/56/edit' => {
        controller => 'people',
        action     => 'edit',
        id         => 56,
    },
    'people/56/remove' => {
        controller => 'people',
        action     => 'remove',
        id         => 56,
    },
    'people/56/update' => {
        controller => 'people',
        action     => 'update',
        id         => 56,
    },
},
"... our routes are solid");

done_testing;
