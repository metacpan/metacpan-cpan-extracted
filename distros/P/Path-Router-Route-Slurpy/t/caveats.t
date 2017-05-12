#!/usr/bin/perl
use strict;
use warnings;

use Test::More tests => 2;

use Path::Router;
use Path::Router::Route::Slurpy;

my $router = Path::Router->new(
    route_class => 'Path::Router::Route::Slurpy',
);

$router->add_route('+:test');

eval {
    $router->match("test");
};

ok($@, 'got an error');
like($@, qr{inline matching mode is not supported}, 'got an error about inline matching mode not being supported');
