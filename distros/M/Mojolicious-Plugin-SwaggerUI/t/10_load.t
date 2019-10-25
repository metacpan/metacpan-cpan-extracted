#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use Test::Mojo;

use Mojolicious::Lite;

my $route = any '/swagger';
plugin 'SwaggerUI', { 
    route => $route,
    url => '/spec',
};

get '/spec' => sub {
    my $c = shift();

    my $spec = {
        swagger => '2.0',
        info => {
            description => 'Description',
            version => '1.0.0',
            title => 'Title'
        },
        paths => {
            '/endpoint' => {
                get => {
                    produces => [ 'application/json' ],
                    responses => {
                        200 => { description => 'OK' }
                    }
                }
            }
        }
    };

    return $c->render(json => $spec);
};

my $t = Test::Mojo->new();

$t->get_ok('/swagger')
    ->status_is(200)
    ->content_type_like(qr/text\/html/xms);

done_testing();