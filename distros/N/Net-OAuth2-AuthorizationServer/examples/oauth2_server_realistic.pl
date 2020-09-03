#!/usr/bin/perl

use strict;
use warnings;

use Mojolicious::Lite;
use Mojo::JSON qw/ decode_json encode_json /;
use FindBin qw/ $Bin /;

chdir( $Bin );

# N.B. this uses a little JSON file, which would not scale - in reality
# you should be using a database of some sort
my $storage_file = "oauth2_db.json";

sub save_oauth2_data {
  my ( $config ) = @_;
  my $json = encode_json( $config );
  open( my $fh,'>',$storage_file )
    || die "Couldn't open $storage_file for write: $!";
  print $fh $json;
  close( $fh );
  return 1;
}

sub load_oauth2_data {
  open( my $fh,'<',$storage_file )
    || die "Couldn't open $storage_file for read: $!";
  my $json;
  while ( my $line = <$fh> ) {
    $json .= $line;
  }
  close( $fh );
  return decode_json( $json );
}

app->config(
  hypnotoad => {
    listen => [ 'https://*:3000' ]
  }
);

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

  my $oauth2_data = load_oauth2_data();

  if ( my $client = $oauth2_data->{clients}{$client_id} ) {

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

  my $oauth2_data = load_oauth2_data();

  my $user_id = $c->session( 'user_id' );

  $oauth2_data->{auth_codes}{$auth_code} = {
    client_id     => $client_id,
    user_id       => $user_id,
    expires       => time + $expires_in,
    redirect_uri  => $uri,
    scope         => { map { $_ => 1 } @{ $scopes_ref } },
  };

  $oauth2_data->{auth_codes_by_client}{$client_id} = $auth_code;

  save_oauth2_data( $oauth2_data );

  return;
};

my $verify_auth_code_sub = sub {
  my ( %args ) = @_;

  my ( $c,$client_id,$client_secret,$auth_code,$uri )
      = @args{qw/ mojo_controller client_id client_secret auth_code redirect_uri / };

  my $oauth2_data = load_oauth2_data();

  my $client = $oauth2_data->{clients}{$client_id}
    || return ( 0,'unauthorized_client' );

  return ( 0,'invalid_grant' )
    if ( $client_secret ne $client->{client_secret} );

  if (
    ! exists( $oauth2_data->{auth_codes}{$auth_code} )
    or ! exists( $oauth2_data->{clients}{$client_id} )
    or ( $client_secret ne $oauth2_data->{clients}{$client_id}{client_secret} )
    or $oauth2_data->{auth_codes}{$auth_code}{access_token}
    or ( $uri && $oauth2_data->{auth_codes}{$auth_code}{redirect_uri} ne $uri )
    or ( $oauth2_data->{auth_codes}{$auth_code}{expires} <= time )
  ) {

    if ( $oauth2_data->{verified_auth_codes}{$auth_code} ) {
      # the auth code has been used before - we must revoke the auth code
      # and access tokens
      my $auth_code_data = delete( $oauth2_data->{auth_codes}{$auth_code} );
      $oauth2_data = _revoke_access_token( $c,$auth_code_data->{access_token} );
      save_oauth2_data( $oauth2_data );
    }

    return ( 0,'invalid_grant' );
  }

  # scopes are those that were requested in the authorization request, not
  # those stored in the client (i.e. what the auth request restriced scopes
  # to and not everything the client is capable of)
  my $scope = $oauth2_data->{auth_codes}{$auth_code}{scope};
  my $user_id = $oauth2_data->{auth_codes}{$auth_code}{user_id};

  $oauth2_data->{verified_auth_codes}{$auth_code} = 1;

  save_oauth2_data( $oauth2_data );

  return ( $client_id,undef,$scope,$user_id );
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

  my $oauth2_data = load_oauth2_data();
  my $user_id;

  if ( ! defined( $auth_code ) && $old_refresh_token ) {
    # must have generated an access token via a refresh token so revoke the old
    # access token and refresh token and update the oauth2_data->{auth_codes}
    # hash to store the new one (also copy across scopes if missing)
    $auth_code = $oauth2_data->{refresh_tokens}{$old_refresh_token}{auth_code};

    my $prev_access_token
      = $oauth2_data->{refresh_tokens}{$old_refresh_token}{access_token};

    # access tokens can be revoked, whilst refresh tokens can remain so we
    # need to get the data from the refresh token as the access token may
    # no longer exist at the point that the refresh token is used
    $scope //= $oauth2_data->{refresh_tokens}{$old_refresh_token}{scope};
    $user_id = $oauth2_data->{refresh_tokens}{$old_refresh_token}{user_id};

    $c->app->log->debug( "OAuth2::Server: Revoking old access tokens (refresh)" );
    $oauth2_data = _revoke_access_token( $c,$prev_access_token );

  } else {
    $user_id = $oauth2_data->{auth_codes}{$auth_code}{user_id};
  }

  if ( ref( $client ) ) {
    $scope  = $client->{scope};
    $client = $client->{client_id};
  }

  # if the client has en existing refresh token we need to revoke it
  delete( $oauth2_data->{refresh_tokens}{$old_refresh_token} )
    if $old_refresh_token;

  $oauth2_data->{access_tokens}{$access_token} = {
    scope         => $scope,
    expires       => time + $expires_in,
    refresh_token => $refresh_token,
    client_id     => $client,
    user_id       => $user_id,
  };

  $oauth2_data->{refresh_tokens}{$refresh_token} = {
    scope         => $scope,
    client_id     => $client,
    user_id       => $user_id,
    auth_code     => $auth_code,
    access_token  => $access_token,
  };

  $oauth2_data->{auth_codes}{$auth_code}{access_token} = $access_token;

  $oauth2_data->{refresh_tokens_by_client}{$client} = $refresh_token;

  save_oauth2_data( $oauth2_data );
  return;
};

my $verify_access_token_sub = sub {
  my ( %args ) = @_;

  my ( $c,$access_token,$scopes_ref,$is_refresh_token )
        = @args{qw/ mojo_controller access_token scopes is_refresh_token /};

  my $oauth2_data = load_oauth2_data();

  if (
    $is_refresh_token
	&& exists( $oauth2_data->{refresh_tokens}{$access_token} )
  ) {

    if ( $scopes_ref ) {
      foreach my $scope ( @{ $scopes_ref // [] } ) {
        if (
          ! exists( $oauth2_data->{refresh_tokens}{$access_token}{scope}{$scope} )
          or ! $oauth2_data->{refresh_tokens}{$access_token}{scope}{$scope}
        ) {
          $c->app->log->debug( "OAuth2::Server: Refresh token does not have scope ($scope)" );
          return ( 0,'invalid_grant' );
        }
      }
    }

    return (
		$oauth2_data->{refresh_tokens}{$access_token},
		undef,
		$oauth2_data->{refresh_tokens}{$access_token}{scope},
		$oauth2_data->{refresh_tokens}{$access_token}{user_id},
	);
  }
  if ( exists( $oauth2_data->{access_tokens}{$access_token} ) ) {

    if ( $oauth2_data->{access_tokens}{$access_token}{expires} <= time ) {
      $c->app->log->debug( "OAuth2::Server: Access token has expired" );
      $oauth2_data = _revoke_access_token( $c,$access_token );
      return ( 0,'invalid_grant' );
    } elsif ( $scopes_ref ) {

      foreach my $scope ( @{ $scopes_ref // [] } ) {
        if (
          ! exists( $oauth2_data->{access_tokens}{$access_token}{scope}{$scope} )
          or ! $oauth2_data->{access_tokens}{$access_token}{scope}{$scope}
        ) {
          $c->app->log->debug( "OAuth2::Server: Access token does not have scope ($scope)" );
          return ( 0,'invalid_grant' );
        }
      }

    }

    $c->app->log->debug( "OAuth2::Server: Access token is valid" );
    return (
		$oauth2_data->{access_tokens}{$access_token},
		undef,
		$oauth2_data->{access_tokens}{$access_token}{scope},
		$oauth2_data->{access_tokens}{$access_token}{user_id},
	);
  }

  $c->app->log->debug( "OAuth2::Server: Access token does not exist" );
  return 0;
};

sub _revoke_access_token {
  my ( $c,$access_token ) = @_;

  my $oauth2_data = load_oauth2_data();

  delete( $oauth2_data->{access_tokens}{$access_token} );

  save_oauth2_data( $oauth2_data );
  return $oauth2_data;
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
