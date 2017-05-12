#!/usr/bin/env perl
use Mojo::Base -strict;

use Test::More;

use Mojolicious::Lite;
use Test::Mojo;

plugin 'PPI', 'src_folder' => 't';

get '/file'   => 'file';

my $t = Test::Mojo->new;
$t->get_ok('/file')
  ->status_is(200)
  ->element_exists('pre[ondblclick]')
  ->element_exists('pre.ppi-code')
  ->element_exists('pre.ppi-block')
  ->element_exists('pre#ppi0')
  ->element_exists('pre#ppi0 span.line_number')
  ->text_is('pre#ppi0 span.symbol' => '@world');

done_testing;

__DATA__

@@ file.html.ep
% title 'Inline';
% layout 'basic';
Hello <%= ppi 'test.pl' %>

@@ layouts/basic.html.ep
  <!doctype html><html>
    <head>
      <title><%= title %></title>
    </head>
    <body><%= content %></body>
  </html>
