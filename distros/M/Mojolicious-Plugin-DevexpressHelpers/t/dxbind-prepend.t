#!/usr/bin/env perl

use strict;
use warnings;

use utf8;

# Disable epoll, kqueue and IPv6
BEGIN { $ENV{MOJO_POLL} = $ENV{MOJO_NO_IPV6} = 1 }

use Test::More;
use Test::Mojo;
use Mojolicious::Lite;
plugin 'DevexpressHelpers';
app->log->level('error'); #silence

# routes
get '/'        => 'index';
get '/prepend' => 'prepend';

# Test
my $t = Test::Mojo->new;

# GET / default
$t->get_ok('/')
  ->status_is(200)
  ->element_exists('html body div[class="container"]')
  ->element_exists_not('html body div[id="resource.name"]')
  ->text_is('script' => q{$(window).on("load",function(){
$('<div id="resource.name">').dxTextBox({name: "resource.name",
value: "default value"}).appendTo(".container");
});});

$t->get_ok('/prepend')
  ->status_is(200)
  ->element_exists('html body div[class="container"]')
  ->element_exists_not('html body div[id="resource.name"]')
  ->text_is('script' => q{$(window).on("load",function(){
$('<div id="resource.name">').dxTextBox({name: "resource.name",
value: "default value"}).prependTo(".container");
});});

done_testing;

__DATA__
@@ index.html.ep
% layout 'main';
<div class="container"></div>
%= dxtextbox 'resource.name' => 'default value' => 'Name: ', { appendTo => '.container' }

@@ prepend.html.ep
% layout 'main';
<div class="container"></div>
%= dxtextbox 'resource.name' => 'default value' => 'Name: ', { prependTo => '.container' }


@@ layouts/main.html.ep
<!doctype html>
<html>
    <head>
       <title>Test</title>
    </head>
    <body><%== content %>
%= dxbuild
</body>
</html>