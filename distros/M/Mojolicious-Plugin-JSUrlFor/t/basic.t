#!/usr/bin/env perl
use Mojo::Base -strict;

use Mojolicious::Lite;
use Test::Mojo;
use Test::More;
use lib 'lib';

plugin 'JSUrlFor';

get '/js_url_for';

get '/get_test_route'             => sub { } => 'simple_route';
get '/tests/:my_id/qwer'          => sub { } => 'get_route_with_placeholder';
post '/tests/:my_id/qwer/'        => sub { } => 'post_route_with_placeholder';
any '/tests/:my_id/qwer/*relaxed' => sub { } => 'relaxed_placeholder';
any '/tests/:my_id/:my_id2'       => sub { } => 'two_placeholder';

my $routes = app->routes;
my $parent = $routes->route('/parent')->to( controller => 'Dummy' );
$parent->route('/nested/:nested_id')->to('#dummy')->name('nested');

my $t = Test::Mojo->new;

my @patterns = (
    qr!function url_for\(route_name, captures\)!,
    qr!"js_url_for":"\\?/js_url_for"!,
    qr!"two_placeholder":"\\?/tests\\?/:my_id\\?/:my_id2"!,
    qr!"get_route_with_placeholder":"\\?/tests\\?/:my_id\\?/qwer"!,
    qr!"post_route_with_placeholder":"\\?/tests\\?/:my_id\\?/qwer"!,
    qr!"simple_route":"\\?/get_test_route"!,
    qr!"relaxed_placeholder":"\\?/tests\\?/:my_id\\?/qwer\\?/\*relaxed"!,
    qr!"nested":"\\?/parent\\?/nested\\?/:nested_id"!,
);

foreach my $p ( @patterns ) {

    $t->get_ok('/js_url_for')
      ->status_is(200)
      ->content_like($p, "Pattern [$p] should exist");
}

done_testing;

__DATA__;

@@ js_url_for.html.ep
<%= js_url_for %>
