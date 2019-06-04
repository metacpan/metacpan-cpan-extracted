#!/usr/bin/perl

use strict;
use warnings;

use Mojolicious::Lite;
use Data::Dumper;
use IO::Socket::SSL;

# work around for example only (don't do this in PROD code)
IO::Socket::SSL::set_defaults(
  SSL_verify_mode => IO::Socket::SSL::SSL_VERIFY_NONE,
);

my $host = $ENV{HOST} // '127.0.0.1';

plugin 'OAuth2', {
  overly_attached_social_network => {
     authorize_url => "https://$host:3000/oauth/authorize?response_type=code",
     token_url     => "https://$host:3000/oauth/access_token",
     key           => 'TrendyNewService',
     secret        => 'boo',
     scope         => 'post_images annoy_friends',
  },
};

app->helper(
  delay => sub {
    my $c  = shift;
    my $tx = $c->render_later->tx;
    Mojo::IOLoop->delay(@_)->catch(sub { $c->helpers->reply->exception(pop) and undef $tx })->wait;
  }
);

get '/auth' => sub {
  my $self = shift;
  if ( my $error = $self->param( 'error' ) ) {
    return $self->render(
      text => "Call to overly_attached_social_network returned: $error"
    );
  } else {
    $self->delay(
      sub {
        my $delay = shift;
        $self->oauth2->get_token( overly_attached_social_network => $delay->begin )
      },
      sub {
        my( $delay,$error,$data ) = @_;
        return $self->render( error => $error ) if ! $data->{access_token};
        return $self->render( json => $data );
      },
    );
  }
};

get '/' => sub {
  my ( $c ) = @_;
  $c->render( 'index' );
};

app->start;

# vim: ts=2:sw=2:et

__DATA__
@@ layouts/default.html.ep
<!doctype html><html>
  <head><title>TrendyNewService</title></head>
  <body><h3>Welcome to TrendyNewService</h3><%== content %></body>
</html>

@@ index.html.ep
% layout 'default';
<a href="/auth">Connect to Overly Attached Social Network</a>
