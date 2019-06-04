#!/usr/bin/perl

use strict;
use warnings;

use Mojolicious::Lite;
use Mojo::JSON qw/ decode_json encode_json /;
use MongoDB;
use FindBin qw/ $Bin /;

chdir( $Bin );

my $client = MongoDB::MongoClient->new(
  host           => 'localhost',
  port           => 27017,
  auto_reconnect => 1,
);

{
  my $db = $client->get_database( 'oauth2' );
  my $clients = $db->get_collection( 'clients' );

  if ( ! $clients->find_one({ client_id => 'TrendyNewService' }) ) {
    $clients->insert_one({
      client_id     => "TrendyNewService",
      client_secret => "boo",
      scopes => {
        post_images    => 1,
        track_location => 1,
        annoy_friends  => 1,
        download_data  => 0,
      }
    });
  }
}

app->config(
  hypnotoad => {
    listen => [ 'https://*:3000' ]
  }
);

helper db => sub {
  my $db = $client->get_database( 'oauth2' );
  return $db;
};

my $resource_owner_logged_in_sub = sub {
  my ( %args ) = @_;

  my $c = $args{mojo_controller};

  if ( ! $c->session( 'logged_in' ) ) {
    # we need to redirect back to the /oauth/authorize route after
    # login (with the original params)
    my $uri = join( '?',$c->url_for('current'),$c->url_with->query );
    $c->flash( 'redirect_after_login' => $uri );
    $c->redirect_to( '/oauth/login' );
    return 0;
  }

  return 1;
};

my $resource_owner_confirm_scopes_sub = sub {
  my ( %args ) = @_;

  my ( $c,$client_id,$scopes_ref,$redirect_uri,$response_type )
    = @args{ qw/ mojo_controller client_id scopes redirect_uri response_type / };

  my $is_allowed = $c->flash( "oauth_${client_id}" );

  # if user hasn't yet allowed the client access, or if they denied
  # access last time, we check [again] with the user for access
  if ( ! $is_allowed ) {
    $c->flash( client_id => $client_id );
    $c->flash( scopes    => $scopes_ref );

    my $uri = join( '?',$c->url_for('current'),$c->url_with->query );
    $c->flash( 'redirect_after_login' => $uri );
    $c->redirect_to( '/oauth/confirm_scopes' );
  }

  return ( $is_allowed,undef,$scopes_ref );
};

my $verify_client_sub = sub {
  my ( %args ) = @_;

  my ( $c,$client_id,$scopes_ref,$client_secret,$redirect_uri,$response_type )
      = @args{ qw/ mojo_controller client_id scopes client_secret redirect_uri response_type / };


  if (
    my $client = $c->db->get_collection( 'clients' )
      ->find_one({ client_id => $client_id })
  ) {
      foreach my $scope ( @{ $scopes_ref // [] } ) {

        if ( ! exists( $client->{scopes}{$scope} ) ) {
          $c->app->log->debug( "OAuth2::Server: Client lacks scope ($scope)" );
          return ( 0,'invalid_scope' );
        } elsif ( ! $client->{scopes}{$scope} ) {
          $c->app->log->debug( "OAuth2::Server: Client cannot scope ($scope)" );
          return ( 0,'access_denied' );
        }
      }

      return ( 1 );
  }

  $c->app->log->debug( "OAuth2::Server: Client ($client_id) does not exist" );
  return ( 0,'unauthorized_client' );
};

my $store_auth_code_sub = sub {
  my ( %args ) = @_;

  my ( $c,$auth_code,$client_id,$expires_in,$uri,$scopes_ref ) =
      @args{qw/ mojo_controller auth_code client_id expires_in redirect_uri scopes / };


  my $auth_codes = $c->db->get_collection( 'auth_codes' );

  my $id = $auth_codes->insert_one({
    auth_code    => $auth_code,
    client_id    => $client_id,
    user_id      => $c->session( 'user_id' ),
    expires      => time + $expires_in,
    redirect_uri => $uri,
    scope        => { map { $_ => 1 } @{ $scopes_ref } },
  });

  return;
};

my $verify_auth_code_sub = sub {
  my ( %args ) = @_;

  my ( $c,$client_id,$client_secret,$auth_code,$uri )
      = @args{qw/ mojo_controller client_id client_secret auth_code redirect_uri / };


  my $auth_codes      = $c->db->get_collection( 'auth_codes' );
  my $ac              = $auth_codes->find_one({
    client_id => $client_id,
    auth_code => $auth_code,
  });

  my $client = $c->db->get_collection( 'clients' )
    ->find_one({ client_id => $client_id });

  $client || return ( 0,'unauthorized_client' );

  if (
    ! $ac
    or $ac->{verified}
    or ( $uri ne $ac->{redirect_uri} )
    or ( $ac->{expires} <= time )
    or ( $client_secret ne $client->{client_secret} )
  ) {
    $c->app->log->debug( "OAuth2::Server: Auth code does not exist" )
      if ! $ac;
    $c->app->log->debug( "OAuth2::Server: Client secret does not match" )
      if ( $uri && $ac->{redirect_uri} ne $uri );
    $c->app->log->debug( "OAuth2::Server: Auth code expired" )
      if ( $ac->{expires} <= time );
    $c->app->log->debug( "OAuth2::Server: Client secret does not match" )
      if ( $client_secret ne $client->{client_secret} );

    if ( $ac->{verified} ) {
      # the auth code has been used before - we must revoke the auth code
      # and access tokens
      $c->app->log->debug(
        "OAuth2::Server: Auth code already used to get access token"
      );

      $auth_codes->delete_many({ auth_code => $auth_code });
      $c->db->get_collection( 'access_tokens' )->delete_many({
        access_token => $ac->{access_token}
      });
    }

    return ( 0,'invalid_grant' );
  }

  # scopes are those that were requested in the authorization request, not
  # those stored in the client (i.e. what the auth request restriced scopes
  # to and not everything the client is capable of)
  my $scope = $ac->{scope};

  $auth_codes->update_one( $ac,{ '$set' => { verified => 1 } } );

  return ( $client_id,undef,$scope,$ac->{user_id} );
};

my $store_access_token_sub = sub {
  my ( %args ) = @_;

  my (
    $c,$client,$auth_code,$access_token,$refresh_token,
    $expires_in,$scope,$old_refresh_token
  ) = @args{qw/
    mojo_controller client_id auth_code access_token
    refresh_token expires_in scopes old_refresh_token
  / };

  my $access_tokens  = $c->db->get_collection( 'access_tokens' );
  my $refresh_tokens = $c->db->get_collection( 'refresh_tokens' );

  my $user_id;

  if ( ! defined( $auth_code ) && $old_refresh_token ) {
    # must have generated an access token via a refresh token so revoke the old
    # access token and refresh token (also copy required data if missing)
    my $prt = $c->db->get_collection( 'refresh_tokens' )->find_one({
      refresh_token => $old_refresh_token,
    });

    my $pat = $c->db->get_collection( 'access_tokens' )->find_one({
      access_token => $prt->{access_token},
    });

    # access tokens can be revoked, whilst refresh tokens can remain so we
    # need to get the data from the refresh token as the access token may
    # no longer exist at the point that the refresh token is used
    $scope //= $prt->{scope};
    $user_id = $prt->{user_id};

    $c->app->log->debug( "OAuth2::Server: Revoking old access tokens (refresh)" );
    _revoke_access_token( $c,$pat->{access_token} );

  } else {
    $user_id = $c->db->get_collection( 'auth_codes' )->find_one({
      auth_code => $auth_code,
    })->{user_id};
  }

  if ( ref( $client ) ) {
    $scope  = $client->{scope};
    $client = $client->{client_id};
  }

  # if the client has en existing refresh token we need to revoke it
  $refresh_tokens->delete_many({ client_id => $client, user_id => $user_id });

  $access_tokens->insert_one({
    access_token  => $access_token,
    scope         => $scope,
    expires       => time + $expires_in,
    refresh_token => $refresh_token,
    client_id     => $client,
    user_id       => $user_id,
  });

  $refresh_tokens->insert_one({
    refresh_token => $refresh_token,
    access_token  => $access_token,
    scope         => $scope,
    client_id     => $client,
    user_id       => $user_id,
  });

  return;
};

my $verify_access_token_sub = sub {
  my ( %args ) = @_;

  my ( $c,$access_token,$scopes_ref,$is_refresh_token )
        = @args{qw/ mojo_controller access_token scopes is_refresh_token /};


  my $rt = $c->db->get_collection( 'refresh_tokens' )->find_one({
    refresh_token => $access_token
  });

  if ( $is_refresh_token && $rt ) {

    if ( $scopes_ref ) {
      foreach my $scope ( @{ $scopes_ref // [] } ) {
        if ( ! exists( $rt->{scope}{$scope} ) or ! $rt->{scope}{$scope} ) {
          $c->app->log->debug(
            "OAuth2::Server: Refresh token does not have scope ($scope)"
          );
          return ( 0,'invalid_grant' );
        }
      }
    }

    return $rt;
  }
  elsif (
    my $at = $c->db->get_collection( 'access_tokens' )->find_one({
      access_token => $access_token,
    })
  ) {

    if ( $at->{expires} <= time ) {
      $c->app->log->debug( "OAuth2::Server: Access token has expired" );
      _revoke_access_token( $c,$access_token );
      return ( 0,'invalid_grant' );
    } elsif ( $scopes_ref ) {

      foreach my $scope ( @{ $scopes_ref // [] } ) {
        if ( ! exists( $at->{scope}{$scope} ) or ! $at->{scope}{$scope} ) {
          $c->app->log->debug(
            "OAuth2::Server: Access token does not have scope ($scope)"
          );
          return ( 0,'invalid_grant' );
        }
      }

    }

    $c->app->log->debug( "OAuth2::Server: Access token is valid" );
    return $at;
  }

  $c->app->log->debug( "OAuth2::Server: Access token does not exist" );
  return 0;
};

sub _revoke_access_token {
  my ( $c,$access_token ) = @_;

  $c->db->get_collection( 'access_tokens' )->delete_many({
    access_token => $access_token,  
  });
}

plugin 'OAuth2::Server' => {
  auth_code_ttl             => 300,
  access_token_ttl          => 600,

  login_resource_owner      => $resource_owner_logged_in_sub,
  confirm_by_resource_owner => $resource_owner_confirm_scopes_sub,

  verify_client             => $verify_client_sub,
  store_auth_code           => $store_auth_code_sub,
  verify_auth_code          => $verify_auth_code_sub,
  store_access_token        => $store_access_token_sub,
  verify_access_token       => $verify_access_token_sub,
};

group {
  # /api - must be authorized
  under '/api' => sub {
    my ( $c ) = @_;
    if ( my $auth_info = $c->oauth ) {
      $c->stash( oauth_info => $auth_info ); 
      return 1;
    }
    $c->render( status => 401, text => 'Unauthorized' );
    return undef;
  };

  any '/annoy_friends' => sub {
    my ( $c ) = @_;
    my $user_id = $c->stash( 'oauth_info' )->{user_id};
    $c->render( text => "$user_id Annoyed Friends" );
  };
  any '/post_image'    => sub {
    my ( $c ) = @_;
    my $user_id = $c->stash( 'oauth_info' )->{user_id};
    $c->render( text => "$user_id Posted Image" );
  };
};

any '/api/track_location' => sub {
  my ( $c ) = @_;
  my $auth_info = $c->oauth( 'track_location' )
      || return $c->render( status => 401, text => 'You cannot track location' );
  $c->render( text => "Target acquired: " . $auth_info->{user_id} );
};

get '/' => sub {
  my ( $c ) = @_;
  $c->render( text => "Welcome to Overly Attached Social Network" );
};

get '/oauth/login' => sub {
  my ( $c ) = @_;

  if ( my $redirect_uri = $c->flash( 'redirect_after_login' ) ) {
    $c->flash( 'redirect_after_login' => $redirect_uri );
  }

  if ( $c->session( 'logged_in' ) ) {
    return $c->render( text => 'Logged in!' )
  } else {
    return $c->render( error  => undef );
  }
};

any '/logout' => sub {
  my ( $c ) = @_;
  $c->session( expires => 1 );
  $c->redirect_to( '/' );
};

post '/oauth/login' => sub {
  my ( $c ) = @_;

  my $username = $c->param('username');
  my $password = $c->param('password');

  if ( my $redirect_uri = $c->flash( 'redirect_after_login' ) ) {
    $c->flash( 'redirect_after_login' => $redirect_uri );
  }

  if ( $username eq 'Lee' and $password eq 'P@55w0rd' ) {
    $c->session( logged_in => 1 );
    $c->session( user_id   => $username );
    if ( my $redirect_uri = $c->flash( 'redirect_after_login' ) ) {
       return $c->redirect_to( $redirect_uri );
    } else {
      return $c->render( text => 'Logged in!' )
    }
  } else {
    return $c->render(
      status => 401,
      error  => 'Incorrect username/password',
    );
  }
};

any '/oauth/confirm_scopes' => sub {
  my ( $c ) = @_;

  # in theory we should only ever get here via a redirect from
  # a login (that was itself redirected to from /oauth/authorize
  if ( my $redirect_uri = $c->flash( 'redirect_after_login' ) ) {
    $c->flash( 'redirect_after_login' => $redirect_uri );
  } else {
    return $c->render(
      text => "Got to /confirm_scopes without redirect_after_login?"
    );
  }

  if ( $c->req->method eq 'POST' ) {

    my $client_id = $c->flash( 'client_id' );
    my $allow     = $c->param( 'allow' );

    $c->flash( "oauth_${client_id}" => ( $allow eq 'Allow' ) ? 1 : 0 );

    if ( my $redirect_uri = $c->flash( 'redirect_after_login' ) ) {
      return $c->redirect_to( $redirect_uri );
    }

  } else {
    $c->flash( client_id => $c->flash( 'client_id' ) );
    return $c->render(
      client_id => $c->flash( 'client_id' ),
      scopes    => $c->flash( 'scopes' ),
    );
  }
};

app->secrets( ['Setec Astronomy'] );
app->sessions->cookie_name( 'oauth2_server' );
app->start;

# vim: ts=2:sw=2:et

__DATA__
@@ layouts/default.html.ep
<!doctype html><html>
  <head><title>Overly Attached Social Network</title></head>
  <body><h3>Welcome to Overly Attached Social Network</h3><%== content %></body>
</html>

@@ oauthlogin.html.ep
% layout 'default';
% if ( $error ) {
<b><%= $error %></b>
% }
<p>
  username: Lee<br />
  password: P@55w0rd
</p>
%= form_for '/oauth/login' => (method => 'POST') => begin
  %= label_for username => 'Username'
  %= text_field 'username'

  %= label_for password => 'Password'
  %= password_field 'password'

  %= submit_button 'Log me in', class => 'btn'
% end

@@ oauthconfirm_scopes.html.ep
% layout 'default';
%= form_for 'confirm_scopes' => (method => 'POST') => begin
  <%= $client_id %> would like to be able to perform the following on your behalf:<ul>
% for my $scope ( @{ $scopes } ) {
  <li><%= $scope %></li>
% }
</ul>
  %= submit_button 'Allow', class => 'btn', name => 'allow'
  %= submit_button 'Deny', class => 'btn', name => 'allow'
% end
