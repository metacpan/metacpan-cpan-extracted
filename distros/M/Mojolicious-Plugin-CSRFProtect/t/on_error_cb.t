#!/usr/bin/env perl
use Mojo::Base -strict;
use Mojolicious::Lite;
use Test::Mojo;
use Test::More;
use lib 'lib';
plugin 'CSRFProtect', on_error => sub {
    my $c = shift;
    $c->render( text => 'Not Found', status => 404 );
};

my $t = Test::Mojo->new;

my $csrftoken;

get '/get_without_token' => sub {
    my $self = shift;
    $csrftoken = $self->csrftoken;
    $self->render( text => 'get_without_token' );
};

post '/post_with_token' => sub {
    my $self = shift;
    $self->render( text => 'valid csrftokentoken' );
};


# GET /get_without_token. First request will generate new token
$t->get_ok('/get_without_token')->status_is(200)->content_is('get_without_token');

# POST /post_with_token
$t->post_ok( "/post_with_token", form => { csrftoken => $csrftoken } )->status_is(200)
    ->content_is('valid csrftokentoken');
$t->post_ok( "/post_with_token", form => { csrftoken => 'wrongtoken' } )->status_is(404)
    ->content_is('Not Found');

done_testing;
