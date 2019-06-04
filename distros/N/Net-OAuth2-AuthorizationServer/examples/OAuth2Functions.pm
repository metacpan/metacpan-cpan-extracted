package OAuth2Functions;

use strict;
use warnings;

use DateTime;
use Exporter::Easy (
	OK => [ qw/
		oauth2_functions
	/ ],
);

sub oauth2_functions {
	my ( $self ) = @_;

	$self->plugin(
		'OAuth2::Server' => {
			login_resource_owner      => \&_resource_owner_logged_in,
			confirm_by_resource_owner => \&_resource_owner_confirm_scopes,

			verify_client             => \&_verify_client,
			store_auth_code           => \&_store_auth_code,
			verify_auth_code          => \&_verify_auth_code,
			store_access_token        => \&_store_access_token,
			verify_access_token       => \&_verify_access_token,
		},
	);

	return 1;
}

sub _resource_owner_logged_in {
  my ( %args ) = @_;

  my $c = $args{mojo_controller};

	if ( ! $c->session( 'session_id' ) ) {
		# we need to redirect back to the /oauth/authorize route after
		# login (with the original params)
		my $uri = join( '?',$c->url_for('current'),$c->url_with->query );
		$c->flash( 'redirect_after_login' => $uri );
		$c->redirect_to( '/oauth/login' );
		return 0;
	}

	return 1;
}

sub _resource_owner_confirm_scopes {
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
}

sub _verify_client {
  my ( %args ) = @_;

  my ( $c,$client_id,$scopes_ref,$client_secret,$redirect_uri,$response_type )
      = @args{ qw/ mojo_controller client_id scopes client_secret redirect_uri response_type / };


	if ( my $client = $c->model->rs( 'Oauth2Client' )->find( $client_id ) ) {

		if ( ! $client->active ) {
			$c->app->log->debug( "Client ($client_id) is not active" );
			return ( 0,'unauthorized_client' );
		}

		foreach my $rqd_scope ( @{ $scopes_ref // [] } ) {

			if ( my $scope = $c->model->rs( 'Oauth2ClientScope' )->find({
				'scope.description' => $rqd_scope,
				'client_id'         => $client_id,
				},{ join => [ qw/ scope / ] }
			) ) {
				if ( ! $scope->allowed ) {
					$c->app->log->debug( "Client disallowed scope ($rqd_scope)" );
					return ( 0,'access_denied' );
				}
			} else {
				$c->app->log->debug( "Client lacks scope ($rqd_scope)" );
				return ( 0,'invalid_scope' );
			}
		}

		return ( 1 );
	}

	$c->app->log->debug( "Client ($client_id) does not exist" );
	return ( 0,'unauthorized_client' );
}

sub _store_auth_code {
  my ( %args ) = @_;

  my ( $c,$auth_code,$client_id,$expires_in,$uri,$scopes_ref ) =
      @args{qw/ mojo_controller auth_code client_id expires_in redirect_uri scopes / };

	my $user_id = $c->session( 'user_id' );

	$c->model->rs( 'Oauth2AuthCode' )->create({
		auth_code        => $auth_code,
		client_id        => $client_id,
		user_id          => $user_id,
		expires          => DateTime->from_epoch( epoch => time + $expires_in ),
		redirect_uri     => $uri,
		verified         => 0,
	});

	foreach my $rqd_scope ( @scopes ) { 
		if ( my $scope = $c->model->rs( 'Oauth2Scope' )->find({
			description => $rqd_scope	
		}) ) {
			$scope->create_related(
				'oauth2_auth_code_scopes',
				{ auth_code => $auth_code, allowed => 1 }
			);
		} else {
			$c->app->log->error(
				"Unknown scope ($rqd_scope) in _store_auth_code"
			);
		}
	}

	return;
}

sub _verify_auth_code {
  my ( %args ) = @_;

  my ( $c,$client_id,$client_secret,$auth_code,$uri )
      = @args{qw/ mojo_controller client_id client_secret auth_code redirect_uri / };


	my $client = $c->model->rs( 'Oauth2Client' )->find( $client_id )
		|| return ( 0,'unauthorized_client' );

	my $ac = $c->model->rs( 'Oauth2AuthCode' )->find({
		client_id => $client_id,
		auth_code => $auth_code,
	});

	if (
		! $ac
		or $ac->verified
		or ( $uri ne $ac->redirect_uri )
		or ( $ac->expires->epoch <= time )
		or ! _check_password( $client_secret,$client->secret )
	) {
		$c->app->log->debug( "Auth code does not exist" )
			if ! $ac;
		$c->app->log->debug( "Client secret does not match" )
			if ! _check_password( $client_secret,$client->secret );

		if ( $ac ) {
			$c->app->log->debug( "Client secret does not match" )
				if ( $uri && $ac->redirect_uri ne $uri );
			$c->app->log->debug( "Auth code expired" )
				if ( $ac->expires->epoch <= time );

			if ( $ac->verified ) {
				# the auth code has been used before - we must revoke the auth code
				# and any associated access tokens (same client_id and user_id)
				$c->app->log->debug(
					"Auth code already used to get access token, "
					. "revoking all associated access tokens"
				);
				$ac->delete;

				if ( my $rs = $c->model->rs( 'Oauth2AccessToken' )->search({
					client_id      => $client_id,
					user_id        => $ac->user_id,
				}) ) {
					while ( my $row = $rs->next ) {
						$row->delete;
					}
				}
			}
		}

		return ( 0,'invalid_grant' );
	}

	$ac->verified( 1 );
	$ac->update;

	# scopes are those that were requested in the authorization request, not
	# those stored in the client (i.e. what the auth request restriced scopes
	# to and not everything the client is capable of)
	my %scope = map { $_->scope->description => 1 }
		$ac->oauth2_auth_code_scopes->all;

	return ( $client_id,undef,{ %scope },$ac->user_id );
}

sub _check_password {
  my ( $hashed_password,$password ) = @_;

  die "Implement _check_password";
}

sub _store_access_token {
  my ( %args ) = @_;

  my (
    $c,$client,$auth_code,$access_token,$refresh_token,
    $expires_in,$scope,$old_refresh_token
  ) = @args{qw/
    mojo_controller client_id auth_code access_token
    refresh_token expires_in scopes old_refresh_token
  / };

	my ( $user_id );

	if ( ! defined( $auth_code ) && $old_refresh_token ) {
		# must have generated an access token via a refresh token so revoke the
		# old access token and refresh token (also copy required data if missing)
		my $prt = $c->model->rs( 'Oauth2RefreshToken' )
			->find( $old_refresh_token );

		my $pat = $c->model->rs( 'Oauth2AccessToken' )
			->find( $prt->access_token );

		# access tokens can be revoked, whilst refresh tokens can remain so we
		# need to get the data from the refresh token as the access token may
		# no longer exist at the point that the refresh token is used
		$scope //= {
			map { $_->scope->description => 1 }
				$prt->oauth2_refresh_token_scopes->all
		};

		$user_id = $prt->user_id;
	} else {
		my $ac = $c->model->rs( 'Oauth2AuthCode' )->find( $auth_code );
		$user_id = $ac->user_id;
	}

	if ( ref( $client ) ) {
		$scope   //= $client->{scope};
		$user_id //= $client->{user_id};
		$client    = $client->{client_id};
	}

	foreach my $token_type ( qw/ Access Refresh / ) {
		# if the client has en existing access/refresh token we need to revoke it
		if ( my $rs = $c->model->rs( "Oauth2${token_type}Token" )->search({
			client_id => $client,
			user_id   => $user_id,
		}) ) {
			$c->app->log->debug( "Revoking existing @{[lc $token_type]} token" );
			while ( my $row = $rs->next ) {
				$row->delete;
			}
		}
	}

	# N.B. you should probably encrypt the access tokens and refresh tokens here
	$c->model->rs( 'Oauth2AccessToken' )->create({
		access_token     => $access_token,
		refresh_token    => $refresh_token,
		client_id        => $client,
		user_id          => $user_id,
		expires          => DateTime->from_epoch( epoch => time + $expires_in ),
	});

	$c->model->rs( 'Oauth2RefreshToken' )->create({
		refresh_token    => $refresh_token,
		access_token     => $access_token,
		client_id        => $client,
		user_id          => $user_id,
	});

	foreach my $rqd_scope ( keys( %{ $scope } ) ) { 
		if ( my $db_scope = $c->model->rs( 'Oauth2Scope' )->find({
			description => $rqd_scope	
		}) ) {
			foreach my $related ( qw/ access_token refresh_token / ) {
				# N.B. you should probably encrypt the access tokens and refresh tokens here
				$db_scope->create_related( "oauth2_${related}_scopes",{
					allowed  => $scope->{$rqd_scope},
					$related => $related eq 'access_token'
   						? $access_token : $refresh_token,
				});
			}
		} else {
			$c->app->log->error(
				"Unknown scope ($rqd_scope) in _store_access_token"
			);
		}
	}

	return;
}

sub _verify_access_token {
  my ( %args ) = @_;

  my ( $c,$access_token,$scopes_ref,$is_refresh_token )
        = @args{qw/ mojo_controller access_token scopes is_refresh_token /};


	if (
		my $rt = $c->model->rs( 'Oauth2RefreshToken' )->find( $access_token )
	) {
		foreach my $scope ( @{ $scopes_ref // [] } ) {

			my $db_scope = $c->model->rs( 'Oauth2RefreshTokenScope' )->find({
				'scope.description' => $scope,
				'refresh_token'     => $access_token,
				},{ join => [ qw/ scope / ] }
			);

			if ( ! $db_scope || ! $db_scope->allowed ) {
				$c->app->log->debug( "Refresh token doesn't have scope ($scope)" );
				return ( 0,'invalid_grant' );
			}
		}

		return $rt->client_id;

	} elsif (
		my $at = $c->model->rs( 'Oauth2AccessToken' )->find( $access_token )
	) {
		if ( $at->expires->epoch <= time ) {
			$c->app->log->debug( "Access token has expired" );
			$at->delete;
			return ( 0,'invalid_grant' );
		}

		foreach my $scope ( @{ $scopes_ref // [] } ) {

			my $db_scope = $c->model->rs( 'Oauth2AccessTokenScope' )->find({
				'scope.description' => $scope,
				'access_token'      => $access_token,
				},{ join => [ qw/ scope / ] }
			);

			if ( ! $db_scope || ! $db_scope->allowed ) {
				$c->app->log->debug( "Access token doesn't have scope ($scope)" );
				return ( 0,'invalid_grant' );
			}
		}

		return {
			client_id => $at->client_id,
			user_id   => $at->user_id,
		};

	} else {
		$c->app->log->debug( "Access token does not exist" );
		return ( 0,'invalid_grant' );
	}

}

1;
