#!/usr/bin/env perl
use Mojo::Base -strict;

use Test::More;

use Mojolicious::Lite;
use Test::Mojo;

plugin 'PPI';

get '/inline' => 'inline';
get '/file'   => 'file';

my $t = Test::Mojo->new;
$t->get_ok('/inline')
  ->status_is(200)
  ->element_exists( 'code.ppi-code' )
  ->text_is('span.symbol' => '@world')
  ->element_exists_not('span.line_number')
  ->element_exists_not('.ppi-code[ondblclick]')
  ->element_exists(".ppi-code[id=ppi0]");

$t->get_ok('/file')
  ->status_is(200)
  ->element_exists( 'pre.ppi-code' )
  ->text_is('span.symbol' => '@world')
  ->element_exists('span.line_number')
  ->element_exists('.ppi-code[ondblclick]')
  ->element_exists(".ppi-code[id=ppi0]");


done_testing;

__DATA__

@@ inline.html.ep
% title 'Inline';
% layout 'basic';
Hello <%= ppi '@world' %>

@@ file.html.ep
% title 'Inline';
% layout 'basic';
Hello <%= ppi 't/test.pl' %>

@@ layouts/basic.html.ep
  <!doctype html><html>
    <head>
      <title><%= title %></title>
    </head>
    <body><%= content %></body>
  </html>
