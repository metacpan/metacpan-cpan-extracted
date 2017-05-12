#!/usr/bin/env perl

use Mojolicious::Lite;

use Test::More;
use Test::Mojo;

use lib 'lib';
use lib '../lib';

use_ok 'Mojolicious::Plugin::CSSLoader';

## Webapp START

plugin('CSSLoader');

any '/hello' => sub {
    my $self = shift;

    $self->css_load( 'second_file.css' );
    $self->render( 'default' );
};

## Webapp END

my $t = Test::Mojo->new;

my $hello_check = qq~<html>
  <head>
  <link rel="stylesheet" href="second_file.css"/>
<link rel="stylesheet" href="css_file.css"/></head>
  <body><h2>Test</h2></body>
</html>
~;

$t->get_ok( '/hello' )->status_is( 200 )->content_is( $hello_check );

done_testing();

__DATA__
@@ default.html.ep
<html>
  <head>
  </head>
  <body><h2>Test</h2></body>
</html>
% css_load( 'css_file.css' );
