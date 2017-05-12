#!/usr/bin/env perl

use Mojolicious::Lite;
use Test::Mojo;

get '/hello' => { layout => 'default' } => sub { shift->render_text('hello') };

plugin 'toto' => nav => [qw/this that theother/],
  sidebar     => {
    this     => ['x/y', 'z/bar', qw/x z/],
    that     => ['z/p', qw/five/],
    theother => [ 'five/six', 'seven/eight', 'seven' ],
  },
  tabs => {
    x   => [qw/a b c/],
    z   => [qw/d e f/],
    five => [qw/f g h/],
    seven  => [qw/i j k/],
  },
  ;

app->start;

1;

