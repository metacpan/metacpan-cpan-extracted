package authorizationcodegrant_tests;

use strict;
use warnings;

use Test::Most;
use Test::Exception;

sub callbacks {
	my ( $Grant ) = @_;
	return (
		verify_client_cb => sub { return Net::OAuth2::AuthorizationServer::AuthorizationCodeGrant::_verify_client( $Grant,@_ ) },
		store_auth_code_cb => sub { return Net::OAuth2::AuthorizationServer::AuthorizationCodeGrant::_store_auth_code( $Grant,@_ ) },
		verify_auth_code_cb => sub { return Net::OAuth2::AuthorizationServer::AuthorizationCodeGrant::_verify_auth_code( $Grant,@_ ) },
		store_access_token_cb => sub { return Net::OAuth2::AuthorizationServer::AuthorizationCodeGrant::_store_access_token( $Grant,@_ ) },
		verify_access_token_cb => sub { return Net::OAuth2::AuthorizationServer::AuthorizationCodeGrant::_verify_access_token( $Grant,@_ ) },
		login_resource_owner_cb => sub { return Net::OAuth2::AuthorizationServer::AuthorizationCodeGrant::_login_resource_owner( $Grant,@_ ) },
		confirm_by_resource_owner_cb => sub { return Net::OAuth2::AuthorizationServer::AuthorizationCodeGrant::_confirm_by_resource_owner( $Grant,@_ ) },
	);
}

sub clients {

	return {
		test_client => {
			client_secret => 'letmein',
			scopes => {
				eat   => 1,
				drink => 0,
				sleep => 1,
			},
		},
	};
}

sub run_tests {
	my ( $Grant,$args ) = @_;

	$args //= {};

	can_ok(
		$Grant,
		qw/
			clients
		/
	);

	ok( $Grant->login_resource_owner,'login_resource_owner' );
	my ( $confirmed,$confirm_error,$scopes_ref ) = $Grant->confirm_by_resource_owner(
		client_id => 'test_client',
		scopes => [ qw/ eat sleep / ],
	);
	
	ok( $confirmed,'confirm_by_resource_owner' );
	ok( !$confirm_error,' ... no error' );
	cmp_deeply( $scopes_ref,[ qw/ eat sleep / ],' ... returned scopes ref' );

	note( "verify_client" );

	my %valid_client = (
		client_id => 'test_client',
		scopes    => $scopes_ref,
	);

	my ( $res,$error ) = $Grant->verify_client( %valid_client );

	ok( $res,'->verify_client, allowed scopes' );
	ok( ! $error,'has no error' );

	foreach my $t (
		[ { scopes => [ qw/ eat sleep yawn / ] },'invalid_scope','invalid scopes' ],
		[ { client_id => 'another_client' },'unauthorized_client','invalid client' ],
	) {
		( $res,$error ) = $Grant->verify_client( %valid_client,%{ $t->[0] } );

		ok( ! $res,'->verify_client, ' . $t->[2] );
		is( $error,$t->[1],'has error' );
	}

    foreach my $t (
		[ { scopes => [ qw/ eat sleep drink / ] },[ qw / eat sleep / ],'disallowed scopes' ],
    ) {
        my $scopes;
        ( $res, $error, $scopes ) = $Grant->verify_client( %valid_client,%{ $t->[0] } );

        ok ( $res, '->verify_client, ' . $t->[2] );
        cmp_deeply( $scopes, $t->[1], 'has reduced scopes' );
    }

	note( "store_auth_code" );

	ok( my $auth_code = $Grant->token(
		client_id    => 'test_client',
		scopes       => $scopes_ref,
		type         => 'auth',
		redirect_uri => 'https://come/back',
		user_id      => 1,
	),'->token (auth code)' );

	$args->{token_format_tests}->( $auth_code,'auth' )
		if $args->{token_format_tests};

	ok( $Grant->store_auth_code(
		client_id    => 'test_client',
		auth_code    => $auth_code,
		redirect_uri => 'https://come/back',
		scopes       => $scopes_ref,
	),'->store_auth_code' );

	note( "verify_auth_code" );

	my %valid_auth_code = (
		client_id     => 'test_client',
		client_secret => 'letmein',
		auth_code     => $auth_code,
		redirect_uri  => 'https://come/back',
	);

	my ( $client,$vac_error,$scopes,$user_id ) = $Grant->verify_auth_code( %valid_auth_code );

	ok( $client,'->verify_auth_code, correct args' );
	ok( ! $vac_error,'has no error' );
	is( $user_id,$args->{no_jwt} ? undef : 1,'user_id' );
	cmp_deeply( $scopes,[ qw/ eat sleep / ],'has scopes' );

	foreach my $t (
		[ { client_id => 'another_client' },'unauthorized_client','invalid client' ],
		[ { client_secret => 'bad secret' },'invalid_grant','bad client secret' ],
		[ { redirect_uri => 'http://not/this' },'invalid_grant','bad redirect uri' ],
	) {
		( $client,$vac_error,$scopes ) = $Grant->verify_auth_code(
			%valid_auth_code,%{ $t->[0] },
		);

		ok( ! $client,'->verify_auth_code, ' . $t->[2] );
		is( $vac_error,$t->[1],'has error' );
		ok( ! $scopes,'has no scopes' );
	}

	my $og_auth_code = $auth_code;
	chop( $auth_code );

	( $client,$vac_error,$scopes ) = $Grant->verify_auth_code(
		%valid_auth_code,
		auth_code => $auth_code,
	);

	ok( ! $client,'->verify_auth_code, token fiddled with' );
	is( $vac_error,'invalid_grant','has error' );
	ok( ! $scopes,'has no scopes' );

	note( "store_access_token" );

	ok( my $access_token = $Grant->token(
		client_id    => 'test_client',
		scopes       => $scopes_ref,
		type         => 'access',
		user_id      => 1,
	),'->token (access token)' );

	$args->{token_format_tests}->( $access_token,'access' )
		if $args->{token_format_tests};

	ok( my $refresh_token = $Grant->token(
		client_id    => 'test_client',
		scopes       => $scopes_ref,
		type         => 'refresh',
		user_id      => 1,
	),'->token (refresh token)' );

	$args->{token_format_tests}->( $refresh_token,'refresh' )
		if $args->{token_format_tests};

	ok( $Grant->store_access_token(
		client_id     => 'test_client',
		auth_code     => $og_auth_code,
		access_token  => $access_token,
		refresh_token => $refresh_token,
		scopes        => $scopes_ref,
	),'->store_access_token' );

	note( "verify_access_token" );

	( $res,$error ) = $Grant->verify_access_token(
		access_token     => $access_token,
		scopes           => $scopes_ref,
		is_refresh_token => 0,
	);

	ok( $res,'->verify_access_token, valid access token' );
	ok( ! $error,'has no error' );

	( $res,$error ) = $Grant->verify_access_token(
		access_token     => $refresh_token,
		scopes           => $scopes_ref,
		is_refresh_token => 1,
	);

	ok( $res,'->verify_access_token, valid refresh token' );
	ok( ! $error,'has no error' );

	( $res,$error ) = $Grant->verify_access_token(
		access_token     => $access_token,
		scopes           => [ qw/ drink / ],
		is_refresh_token => 0,
	);

	ok( ! $res,'->verify_access_token, invalid scope' );
	is( $error,'invalid_grant','has error' );

	( $res,$error ) = $Grant->verify_access_token(
		access_token     => $access_token,
		scopes           => [ qw/ drink / ],
		is_refresh_token => 1,
	);

	ok( ! $res,'->verify_access_token, refresh token is not access token' );
	is( $error,'invalid_grant','has error' );

	( $res,$error ) = $Grant->verify_token_and_scope(
		auth_header      => "Bearer $access_token",
		scopes           => $scopes_ref,
		is_refresh_token => 0,
	);

	ok( $res,'->verify_token_and_scope, valid access token' );
	ok( ! $error,'has no error' );

	( $res,$error ) = $Grant->verify_token_and_scope(
		auth_header   => "Bearer $access_token",
		scopes        => $scopes_ref,
		refresh_token => $refresh_token,
	);

	ok( $res,'->verify_token_and_scope, valid refresh token' );
	ok( ! $error,'has no error' );

	my $og_access_token = $access_token;
	chop( $access_token );

	( $res,$error ) = $Grant->verify_access_token(
		access_token     => $access_token,
		scopes           => $scopes_ref,
		is_refresh_token => 0,
	);

	ok( ! $res,'->verify_access_token, token fiddled with' );
	is( $error,'invalid_grant','has error' );

	unless ( $args->{cannot_revoke} ) {
		note( "verify_auth_code" );
		( $client,$vac_error,$scopes ) = $Grant->verify_auth_code( %valid_auth_code );

		ok( ! $client,'->verify_auth_code, correct args but second time' );
		is( $vac_error,'invalid_grant','has no error' );
		ok( ! $scopes,'has no scopes' );

		( $res,$error ) = $Grant->verify_access_token(
			access_token     => $access_token,
			scopes           => $scopes_ref,
			is_refresh_token => 0,
		);

		ok( ! $res,'->verify_access_token, access token revoked' );
		is( $error,'invalid_grant','has error' );
	}

	return $og_access_token;
}

1;
