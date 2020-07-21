#!perl

use strict;
use warnings;

package Test::Defaults;

use Moo;
with 'Net::OAuth2::AuthorizationServer::Defaults';

use Test::Most;
use Test::Exception;
use Crypt::JWT qw/ decode_jwt /;

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

my $details    = decode_jwt( alg => 'HS256', key => 'Some Secret Key', token => $jwt );

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
	'jwt_claims_cb used (JWT)',
);

SKIP: {
	skip "Couldn't load Mojo::JWT: $@", 1 unless eval 'use Mojo::JWT 0.04; 1';
	my $mj_details = Mojo::JWT->new( secret => 'Some Secret Key' )->decode( $jwt );
	cmp_deeply( $details,$mj_details,'backwards compat with Mojo::JWT' );
}

*Test::Defaults::jwt_algorithm  = sub { 'PBES2-HS512+A256KW' };
*Test::Defaults::jwt_encryption = sub { 'A256CBC-HS512' };

my $jwe = $t->token(
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

$details = decode_jwt( alg => 'PBES2-HS512+A256KW', key => 'Some Secret Key', token => $jwe );

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
	'jwt_claims_cb used (JWE)',
);

*Test::Defaults::jwt_algorithm  = sub { 'none' };

dies_ok(
	sub {
		$t->token(
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
	},
	'algorithm none throws exception'
);

subtest '->access_token_ttl' => sub {

	subtest 'Int' => sub {

		my $Defaults = Test::Defaults->new(
			access_token_ttl => 999,
		);

		is $Defaults->access_token_ttl, 999, 'attribute is numeric';
		is $Defaults->get_access_token_ttl(), 999, '->get_access_token_ttl() returned default numeric TTL';

	};

	subtest 'CodeRef' => sub {

		my $Defaults = Test::Defaults->new(
			access_token_ttl => sub {
				my ( %args ) = @_;

				return {
					Test => 12345,
				}->{ $args{client_id} // '' } // 42;
			},
		);

		is ref( $Defaults->access_token_ttl ), 'CODE', 'attribute is code ref';
		is $Defaults->get_access_token_ttl(), 42, '->get_access_token_ttl() returned our default TTL';
		is $Defaults->get_access_token_ttl( client_id => 'Test' ), 12345,
			'->get_access_token_ttl() returned our custom TTL';

	};


};

like( $@,qr/'none' is not supported/,'with expected error' );

done_testing();
