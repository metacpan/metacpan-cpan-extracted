#!/usr/bin/env perl

use Mojolicious::Lite;

use Test::More;
use Test::Mojo;

use lib 'lib';
use lib '../lib';

use_ok 'Mojolicious::Plugin::JSLoader';

## Webapp START

plugin('JSLoader', { base => 'js/' });

## Webapp END

my $t = Test::Mojo->new;

{
    my $c = $t->app->build_controller;
    my $result = $c->js_load('test.js');
    is $result, 1;
    is_deeply $c->stash->{__JSLOADERFILES__}, [['test.js', {}]];
}

{
    my $c = $t->app->build_controller;
    my $result = $c->js_load('test.js', { check => 1 });
    is $result, 1;
    is_deeply $c->stash->{__JSLOADERFILES__}, [['test.js', { check => 1 }]];
}

{
    my $c = $t->app->build_controller;
    my $result = $c->js_load('test.js', { check => 1, no_base => 1 });
    is $result, 1;
    is_deeply $c->stash->{__JSLOADERFILES__}, [['test.js', { check => 1, no_base => 1 }]];
}

{
    my $c = $t->app->build_controller;
    my $result = $c->js_load('test.js', { inplace => 1 });
    is $result, '<script type="text/javascript" src="js/test.js"></script>';
    is $c->stash->{__JSLOADERFILES__}, undef;
}

{
    my $c = $t->app->build_controller;
    my $result = $c->js_load('test.js', { inplace => 1, no_base => 1 });
    is $result, '<script type="text/javascript" src="test.js"></script>';
    is $c->stash->{__JSLOADERFILES__}, undef;
}


{
    my $c = $t->app->build_controller;
    my $result = $c->js_load('console.debug("inplace and js");', { inplace => 1, js => 1 });
    is $result, '<script type="text/javascript">console.debug("inplace and js");</script>';
    is $c->stash->{__JSLOADERFILES__}, undef;
}

done_testing();

__DATA__
@@ test.js
console.log('test');

@@ js/test.js
console.log('test');
