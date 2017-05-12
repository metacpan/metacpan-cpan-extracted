#!/usr/bin/env perl
use Mojo::Base -strict;

use Test::More tests => 10;

use Mojolicious::Lite;
use Test::Mojo;

plugin 'PPI';

get '/block' => 'block';
get '/block-inline' => 'block-inline';

my $t = Test::Mojo->new;
$t->get_ok('/block')
  ->status_is(200)
  ->element_exists( 'pre.ppi-code' )
  ->text_is('span.symbol' => '@world')
  ->element_exists('span.line_number');

$t->get_ok('/block-inline')
  ->status_is(200)
  ->element_exists( 'code.ppi-code' )
  ->text_is('span.symbol' => '@world')
  ->element_exists_not('span.line_number');

__DATA__

@@ block.html.ep
% title 'Inline';
% layout 'basic';
Hello
%= ppi begin
  @world
%= end

@@ block-inline.html.ep
% title 'Inline';
% layout 'basic';
Hello
%= ppi {inline => 1 }, begin
  @world
%= end

@@ layouts/basic.html.ep
  <!doctype html><html>
    <head>
      <title><%= title %></title>
    </head>
    <body><%= content %></body>
  </html>
