#!/usr/bin/perl

use strict;
use warnings;

use Test::More 1.001013;
use Test::Path::Router;
use Path::Router;

my $router = Path::Router->new;

$router->add_route('/wiki/?:page' => (
    defaults => {
        controller => 'wiki',
        page       => 'HomePage',
    }
));

$router->add_route('/css/:style' => (
    defaults => {
        controller => 'css'
    }
));

is(
    $router->uri_for(page => 'whatever'),
    'wiki/whatever',
    '... got the right URI'
);

is(
    $router->uri_for(style => 'mystyle'),
    'css/mystyle',
    '... got the right URI'
);

is(
    $router->uri_for(style => 'wiki'),
    'css/wiki',
    '... got the right URI'
);

is(
    $router->uri_for(controller => 'wiki'),
    'wiki',
    'defaults correctly excluded (no trailing slash)',
);

done_testing;
