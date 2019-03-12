#!/usr/bin/env perl

use Mojolicious::Lite;

use Test::More;
use Test::Mojo;

use lib 'lib';
use lib '../lib';

use_ok 'Mojolicious::Plugin::JSLoader';

use Mojo::Collection;

## Webapp START

plugin('JSLoader');

## Webapp END

my $t = Test::Mojo->new;
my $c = $t->app->build_controller;

{
    my $result = Mojolicious::Plugin::JSLoader::_match_browser( $c, 'test.js' );
    is $result, 1;
}

{
    my $result = Mojolicious::Plugin::JSLoader::_match_browser( $c, 'test.js', undef );
    is $result, 1;
}

{
    my $result = Mojolicious::Plugin::JSLoader::_match_browser( $c, 'test.js', [] );
    is $result, 1;
}

{
    my $result = Mojolicious::Plugin::JSLoader::_match_browser( $c, 'test.js', 'string' );
    is $result, 1;
}

{
    my $result = Mojolicious::Plugin::JSLoader::_match_browser( $c, 'test.js', { browser => 'IE5' } );
    is $result, 1;
}

{
    my $result = Mojolicious::Plugin::JSLoader::_match_browser( $c, 'test.js', Mojo::Collection->new(1,2) );
    is $result, 1;
}

$c->req->headers->user_agent("Mozilla/5.0 (Macintosh; U; Intel Mac OS X 10_5_2; en-us) AppleWebKit/525.18 (KHTML, like Gecko) Version/3.1.1 Safari/525.18");

{
    my $result = Mojolicious::Plugin::JSLoader::_match_browser( $c, 'test.js', {
        browser => {
            'Internet Explorer' => 3,
        },
    } );
    is $result, '';
}

{
    my $result = Mojolicious::Plugin::JSLoader::_match_browser( $c, 'test.js', {
        browser => {
            'Internet Explorer' => 3,
            default             => 1,
        },
    } );
    is $result, 1;
}

{
    my $result = Mojolicious::Plugin::JSLoader::_match_browser( $c, 'test.js', {
        browser => {
            Safari => 'test',
        },
    } );
    is $result, undef;
}


{
    my $result = Mojolicious::Plugin::JSLoader::_match_browser( $c, 'test.js', {
        browser => {
            Safari => 1,
        },
    } );
    is $result, '';
}

{
    my $result = Mojolicious::Plugin::JSLoader::_match_browser( $c, 'test.js', {
        browser => {
            Safari => 'lt 4',
        },
    } );
    is $result, 1;
}

{
    my $result = Mojolicious::Plugin::JSLoader::_match_browser( $c, 'test.js', {
        browser => {
            Safari => 'gt 3',
        },
    } );
    is $result, 1;
}

{
    my $result = Mojolicious::Plugin::JSLoader::_match_browser( $c, 'test.js', {
        browser => {
            Safari => '! 3.1.1',
        },
    } );
    is $result, '';
}

{
    my $result = Mojolicious::Plugin::JSLoader::_match_browser( $c, 'test.js', {
        browser => {
            Safari => '! 3.1.2',
        },
    } );
    is $result, 1;
}

done_testing();

