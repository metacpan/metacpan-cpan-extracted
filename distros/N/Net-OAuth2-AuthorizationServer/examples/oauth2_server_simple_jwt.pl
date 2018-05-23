#!/usr/bin/perl

use strict;
use warnings;

use Mojolicious::Lite;
use Mojo::JWT;

plugin 'OAuth2::Server' => {
  jwt_secret => "Is it secret?, Is it safe?",
  clients => {
    TrendyNewService => {
      client_secret => 'boo',
      scopes        => {
        "post_images"   => 1,
        "annoy_friends" => 1,
      },
    },
  }
};

group {
  # /api - must be authorized
  under '/api' => sub {
    my ( $c ) = @_;
    return 1 if $c->oauth;
    $c->render( status => 401, text => 'Unauthorized' );
    return undef;
  };

  any '/annoy_friends' => sub { shift->render( text => "Annoyed Friends" ); };
  any '/post_image'    => sub { shift->render( text => "Posted Image" ); };

};

any '/api/track_location' => sub {
  my ( $c ) = @_;
  $c->oauth( 'track_location' )
      || return $c->render( status => 401, text => 'You cannot track location' );
  $c->render( text => "Target acquired" );
};

get '/' => sub {
  my ( $c ) = @_;
  $c->render( text => "Welcome to Overly Attached Social Network" );
};

app->start;

# vim: ts=2:sw=2:et
