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

app->start();

__DATA__;

@@ js_url_for.html.ep
<%= js_url_for %>
