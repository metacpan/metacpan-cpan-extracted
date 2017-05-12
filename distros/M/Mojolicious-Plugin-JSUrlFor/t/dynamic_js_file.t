#!/usr/bin/env perl
use Mojo::Base -strict;

use Mojolicious::Lite;
use Test::Mojo;
use Test::More;
use lib 'lib';

plugin 'JSUrlFor', {route => '/javascript/routes_dynamic_url.js'};
get '/get_test_route' => sub { } => 'simple_route';

my $t = Test::Mojo->new;

my @patterns = (
    'function url_for\\(route_name, captures\\)',
    '"simple_route":"\\\\?/get_test_route"'
);

foreach my $p ( @patterns ) {
    $t->get_ok('/javascript/routes_dynamic_url.js')
      ->status_is(200)
      ->content_type_is('application/javascript')
      ->content_like(qr/$p/, "Pattern [$p] should exist")
      ->content_unlike(qr/<script/, 'Should content no script tag');
}

done_testing;
