#!/usr/bin/env perl
use Mojo::Base -strict;
use Mojolicious::Lite;
use Test::Mojo;
use Test::More;
use lib 'lib';
plugin 'CSRFProtect';

my $t = Test::Mojo->new;

my $csrftoken;

get '/get_without_token' => sub {
    my $self = shift;
    $csrftoken = $self->csrftoken;
    $self->render( text => 'get_without_token' );
};

options '/options_without_token' => sub {
    my $self = shift;
    $csrftoken = $self->csrftoken;
    $self->render( text => 'options_without_token' );
};

get '/protected_document';

get '/get_with_token/:csrftoken' => sub {
    my $self = shift;

    if ( $self->is_valid_csrftoken() ) {
        $self->render( text => 'valid csrftokentoken', status => 200 );
    } else {
        $self->render( text => 'Forbidden!', status => 403 );
    }

};

post '/post_with_token' => sub {
    my $self = shift;
    $self->render( text => 'valid csrftokentoken');
};

# GET /get_without_token. First request will generate new token
$t->get_ok('/get_without_token')->status_is(200)->content_is('get_without_token');


subtest 'Basic test' => sub {
    # GET/OPTIONS without_token
    $t->get_ok('/get_without_token')->status_is(200)->content_is('get_without_token');
    $t->options_ok('/options_without_token')->status_is(200)->content_is('options_without_token');

    # GET /get_with_token
    $t->get_ok("/get_with_token/$csrftoken")->status_is(200)->content_is('valid csrftokentoken');
    $t->get_ok("/get_with_token/wrongtoken")->status_is(403)->content_is('Forbidden!');

    # POST /post_with_token
    $t->post_ok( "/post_with_token", form => { csrftoken => $csrftoken } )->status_is(200)
        ->content_is('valid csrftokentoken');
    $t->post_ok( "/post_with_token", form => { csrftoken => 'wrongtoken' } )->status_is(403)
        ->content_is('Forbidden!');
};


subtest 'Emulate AJAX requests' => sub {
    # AJAX request should be checked (including GET)
    $t->ua->on(
        start => sub {
            my ( $ua, $tx ) = @_;
            $tx->req->headers->header( 'X-Requested-With', 'XMLHttpRequest' );
        } );

    # GET/OPTIONS without_token
    $t->get_ok('/get_without_token')->status_is(200)->content_is('get_without_token');
    $t->options_ok('/options_without_token')->status_is(200)->content_is('options_without_token');

    $t->post_ok( "/post_with_token", form => { csrftoken => $csrftoken } )->status_is(200)
        ->content_is('valid csrftokentoken');
    $t->post_ok( "/post_with_token", form => { csrftoken => 'wrongtoken' } )->status_is(403)
        ->content_is('Forbidden!');

    # Add header with csrftoken
    $t->ua->on(
        start => sub {
            my ( $ua, $tx ) = @_;
            $tx->req->headers->header( 'X-CSRF-Token', $csrftoken );
        } );

    # All request should pass
    $t->get_ok('/get_without_token')->status_is(200)->content_is('get_without_token');
    $t->get_ok("/get_with_token/notoken")->status_is(200)->content_is('valid csrftokentoken');
    $t->post_ok("/post_with_token")->status_is(200)->content_is('valid csrftokentoken');

    # Check helpers
    my $javascript = qq~<meta name="csrftoken" content="$csrftoken"/><script type="text/javascript"> jQuery(document).ajaxSend(function(e, xhr, options) {     var token = jQuery("meta[name='csrftoken']").attr("content"); xhr.setRequestHeader("X-CSRF-Token", token); });</script>\n~;
    $t->get_ok('/protected_document')->status_is(200)->content_is("$javascript");

};


done_testing;

__DATA__;

@@ protected_document.html.ep
<%= jquery_ajax_csrf_protection %>
