#!/usr/bin/perl

use strict;
use warnings;

use Test::More 1.001013;
use Test::Path::Router;
use Path::Router;

my $router = Path::Router->new;

$router->add_route('/' => (
    defaults => {
        controller => 'root',
        action     => 'index',
    }
));

$router->add_route('/name/?:first' => (
    defaults => {
        controller => 'name',
    },
));

$router->add_route('/:name' => (
    defaults => {
        controller => 'root',
        action     => 'hello',
    },
));

mapping_is(
    $router,
    {
        controller => 'root',
        action     => 'index',
    },
    '',
    'return "" for /',
);

mapping_is(
    $router,
    {
        controller => 'root',
        action     => 'bogus',
    },
    undef,
    'return undef for bogus mapping',
);

mapping_is(
    $router,
    {
        name       => 'world',
    },
    'world',
    'match with only component variables',
);

mapping_is(
    $router,
    {
        first      => 'Sally',
    },
    'name/Sally',
    'match with only optional component variables',
);

mapping_is(
    $router,
    {
        controller => 'root',
        action     => 'hello',
        name       => 'world',
    },
    'world',
    'match with extra variables',
);

mapping_is(
    $router,
    {
        controller => 'root',
        name       => 'world',
    },
    'world',
    'match with partial defaults',
);

mapping_is(
    $router,
    {
        controller => 'root',
        action     => 'hello',
    },
    undef,
    'do not match with missing component variable',
);

done_testing;
