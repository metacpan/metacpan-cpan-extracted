#!perl

use strict;
use warnings;

package Test::Defaults;

use Moo;
with 'Net::OAuth2::AuthorizationServer::Defaults';

use Test::Most;
use Test::Exception;
use Mojo::JWT;

isa_ok( my $t = Test::Defaults->new,'Test::Defaults' );

throws_ok(
	sub { $t->_uses_auth_codes },
	qr/You must override _uses_auth_codes/,
    '_uses_auth_codes must be overriden in subclass',
);

ok( ! $t->_has_clients,'! _has_clients' );

my ( $res,$error ) = $t->verify_token_and_scope( auth_header => "Foo Bar" );
is( $error,'invalid_request','verify_token_and_scope with bad auth_header' );

no warnings 'redefine';
no warnings 'once';
*Test::Defaults::_uses_auth_codes = sub { 0 };
*Test::Defaults::jwt_secret       = sub { 'Some Secret Key' };

my $jwt = $t->token(
	client_id     => 1,
	scopes        => [ qw/ eat sleep / ],
	type          => 'access',
	redirect_uri  => 'https://foo.com/cb',
	user_id       => 2,
	jwt_claims_cb => sub { 
		my ( $args ) = @_;
		return (
			user_id => $args->{user_id} + 1,
			iss     => "some iss",
			sub     => "not the passed user_id",
		);
	}
);

my $details = Mojo::JWT->new( secret => 'Some Secret Key' )
	->decode( $jwt );

cmp_deeply(
	$details,
	{
		'exp'     => ignore(),
		'type'    => 'access',
		'aud'     => 'https://foo.com/cb',,
		'client'  => 1,
		'user_id' => 3,
		'iat'     => re( '^\d{10}$' ),
		'jti'     => re( '^.{32}$' ),
		'iss'     => "some iss",
		'sub'     => "not the passed user_id",
		'scopes'  => [
		  'eat',
		  'sleep',
		]
	},
	'jwt_claims_cb used',
);

done_testing();
