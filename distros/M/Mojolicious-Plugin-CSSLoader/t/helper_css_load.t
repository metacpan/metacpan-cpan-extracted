#!/usr/bin/env perl

use Mojolicious::Lite;

use Test::More;
use Test::Mojo;

use lib 'lib';
use lib '../lib';

use_ok 'Mojolicious::Plugin::CSSLoader';

## Webapp START

plugin('CSSLoader' => { base => 'css/' });

## Webapp END

my $t = Test::Mojo->new;
my $controller = $t->app->build_controller;

$controller->css_load( 'test.css', { check => 1, no_base => 1 } );
is_deeply $controller->stash->{__CSSLOADERFILES__}, [ [ 'test.css', { check => 1, no_base => 1 } ] ];


done_testing();

__DATA__

@@ test.css
.test { color: #ffffff; }
