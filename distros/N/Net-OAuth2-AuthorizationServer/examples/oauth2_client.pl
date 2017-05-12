#!perl

use strict;
use warnings;

use Mojolicious::Lite;

my $host = $ENV{HOST} // '127.0.0.1';

plugin 'OAuth2', {
  fix_get_token => 1,
  overly_attached_social_network => {
     authorize_url => "https://$host:3000/oauth/authorize?response_type=code",
     token_url     => "https://$host:3000/oauth/access_token",
     key           => 'TrendyNewService',
     secret        => 'boo',
     scope         => 'post_images annoy_friends',
  },
};

get '/' => sub {
  my ( $c ) = @_;
  $c->render( 'index' );
};

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
