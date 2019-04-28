#!perl

use strict;
use warnings;

use Test::Most;
use Test::Exception;
use Crypt::JWT qw/ decode_jwt /;

use FindBin qw/ $Bin /;
use lib "$Bin";
use clientcredentialsgrant_tests;

use_ok( 'Net::OAuth2::AuthorizationServer::ClientCredentialsGrant' );

throws_ok(
	sub {
		Net::OAuth2::AuthorizationServer::ClientCredentialsGrant->new;
	},
	qr/requires either clients or overrides/,
    'constructor with no args throws'
);

my $Grant;

foreach my $with_callbacks ( 0,1 ) {

	isa_ok(
		$Grant = Net::OAuth2::AuthorizationServer::ClientCredentialsGrant->new(
			jwt_secret => 'Some Secret Key',
			clients    => clientcredentialsgrant_tests::clients(),

			# am passing in a reference to the modules subs to ensure we hit
			# the code paths to call callbacks
			( $with_callbacks ? (
				clientcredentialsgrant_tests::callbacks( $Grant )
			) : () ), 


		),
		'Net::OAuth2::AuthorizationServer::ClientCredentialsGrant'
	);

	my $access_token = clientcredentialsgrant_tests::run_tests( $Grant,{
		token_format_tests => \&token_format_tests,
		cannot_revoke      => 1, # because we set jwt_secret
	} );

	my ( $res,$error ) = $Grant->verify_token_and_scope(
		auth_header   => undef,
		scopes        => [ qw/ eat sleep / ],
		refresh_token => 0,
	);

	ok( ! $res,'->verify_token_and_scope, no auth header' );
	is( $error,'invalid_request','has error' );

	chop( $access_token );

	( $res,$error ) = $Grant->verify_access_token(
		access_token     => $access_token,
		scopes           => [ qw/ eat sleep / ],
		is_refresh_token => 0,
	);

	ok( ! $res,'->verify_access_token, access token revoked' );
	is( $error,'invalid_grant','has error' );
}

done_testing();

sub token_format_tests {
	my ( $token,$type ) = @_;

	like( $token,qr/\./,'token looks like a JWT' );

	cmp_deeply(
		decode_jwt( alg => 'HS256', key => 'Some Secret Key', token => $token ),
		{
			'aud' => $type eq 'auth' ? 'https://come/back' : undef,
			'client' => 'test_client',
			( $type eq 'refresh' ? () : ( 'exp' => ignore() ) ),
			'iat' => ignore(),
			'jti' => ignore(),
			'scopes' => [
				'eat',
				'sleep'
			],
			'type' => $type,
			'user_id' => 1
		},
		'auth code decodes correctly',
	);
}
