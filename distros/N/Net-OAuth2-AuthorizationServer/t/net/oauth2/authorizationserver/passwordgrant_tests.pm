package passwordgrant_tests;

use strict;
use warnings;

use Test::Most;
use Test::Exception;
use authorizationcodegrant_tests;

sub callbacks {
	my ( $Grant ) = @_;
	return (
		verity_user_password_cb => sub { return Net::OAuth2::AuthorizationServer::PasswordGrant::_verify_user_password( $Grant,@_ ) },
		store_access_token_cb => sub { return Net::OAuth2::AuthorizationServer::PasswordGrant::_store_access_token( $Grant,@_ ) },
		verify_access_token_cb => sub { return Net::OAuth2::AuthorizationServer::PasswordGrant::_verify_access_token( $Grant,@_ ) },
		login_resource_owner_cb => sub { return Net::OAuth2::AuthorizationServer::PasswordGrant::_login_resource_owner( $Grant,@_ ) },
		confirm_by_resource_owner_cb => sub { return Net::OAuth2::AuthorizationServer::PasswordGrant::_confirm_by_resource_owner( $Grant,@_ ) },
	);
}

sub clients {
	return authorizationcodegrant_tests::clients();
}

sub users {
	return {
		test_user => 'reallyletmein',
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

	note( "verify_user_password" );

	my %valid_user_password = (
		client_id     => 'test_client',
		client_secret => 'letmein',
		username      => 'test_user',
		password      => 'reallyletmein',
		scopes        => $scopes_ref,
	);

	my ( $og_client,$vac_error,$scopes,$user_id )
		= $Grant->verify_user_password( %valid_user_password );

	ok( $og_client,'->verify_user_password, correct args' );
	ok( ! $vac_error,'has no error' );
	cmp_deeply( $scopes,$scopes_ref,'has scopes' );

	foreach my $t (
		[ { client_id => 'another_client' },'unauthorized_client','invalid client' ],
		[ { client_secret => 'bad secret' },'invalid_grant','bad client secret' ],
		[ { username => 'i_do_not_exist' },'invalid_grant','bad username' ],
		[ { password => 'bad_password' },'invalid_grant','bad password' ],
	) {
		my ( $rt_client,$vac_error,$scopes ) = $Grant->verify_user_password(
			%valid_user_password,%{ $t->[0] },
		);

		ok( ! $rt_client,'->verify_user_password, ' . $t->[2] );
		is( $vac_error,$t->[1],'has error' );
		ok( ! $scopes,'has no scopes' );
	}

	my $client = $og_client;

	note( "store_access_token" );

	ok( my $access_token = $Grant->token(
		client_id    => 'test_client',
		scopes       => $scopes_ref,
		type         => 'access',
		user_id      => $user_id,
	),'->token (access token)' );

	$args->{token_format_tests}->( $access_token,'access' )
		if $args->{token_format_tests};

	ok( my $refresh_token = $Grant->token(
		client_id    => 'test_client',
		scopes       => $scopes_ref,
		type         => 'refresh',
		user_id      => $user_id,
	),'->token (refresh token)' );

	$args->{token_format_tests}->( $refresh_token,'refresh' )
		if $args->{token_format_tests};

	ok( $Grant->store_access_token(
		client_id     => 'test_client',
		access_token  => $access_token,
		refresh_token => $refresh_token,
		scopes       => $scopes_ref,
	),'->store_access_token' );

	note( "verify_access_token" );

	my ( $res,$error ) = $Grant->verify_access_token(
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

	return $og_access_token;
}

1;
