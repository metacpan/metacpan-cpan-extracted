#!perl

use strict;
use warnings;

use Mojo::URL;
use Mojolicious::Lite;
use Test::More;
use Test::Mojo;
use Test::Deep;

my $TTL_callback = sub {
	my ( %args ) = @_;

	return {
		TestClient => 99999,
	}->{ $args{client_id} // '' } // 12345;
};

MOJO_APP: {
# plugin configuration
plugin 'OAuth2::Server' => {
	auth_code_ttl    => 3600,
	access_token_ttl => $TTL_callback,
	clients          => {
		TestClient => {
			client_secret => 'boo',
		},
		TTLDefaultClient => {
			client_secret => 'banana',
		},
	},
};

group {
	# /api - must be authorized
	under '/api' => sub {
		my ( $c ) = @_;
		return 1 if $c->oauth && $c->oauth->{client_id};
		$c->render( status => 401, text => 'Unauthorized' );
		return undef;
	};
};
};

my $t = Test::Mojo->new;
my $auth_route  = '/oauth/authorize';
my $token_route = '/oauth/access_token';

note('see t/030_expiry_config.t for token expiry tests, we only verify access token callback here');

subtest 'TestClient: custom TTL' => sub {

	my %valid_auth_params = (
		client_id     => 'TestClient',
		client_secret => 'boo',
		response_type => 'code',
		redirect_uri  => 'https://client/cb',
		state         => 'queasy',
	);

	$t->get_ok( $auth_route => form => \%valid_auth_params )
		->status_is( 302 )
		;

	my $location = Mojo::URL->new( $t->tx->res->headers->location );
	is( $location->path,'/cb','redirect to right place' );
	ok( my $auth_code = $location->query->param( 'code' ),'includes code' );
	is( $location->query->param( 'state' ),'queasy','includes state' );

	my %valid_token_params = (
		client_id     => 'TestClient',
		client_secret => 'boo',
		grant_type    => 'authorization_code',
		code          => $auth_code,
		redirect_uri  => $valid_auth_params{redirect_uri},
	);

	$t->post_ok( $token_route => form => \%valid_token_params )
		->status_is( 200 )
		->header_is( 'Cache-Control' => 'no-store' )
		->header_is( 'Pragma'        => 'no-cache' )
		;

	cmp_deeply(
		$t->tx->res->json,
		{
			scopes        => ignore(),
			access_token  => re( '^.+$' ),
			token_type    => 'Bearer',
			expires_in    => 99999,
			refresh_token => re( '^.+$' ),
		},
		'json_is_deeply'
	);

};

subtest 'TTLDefaultClient: default TTL' => sub {

	my %valid_auth_params = (
		client_id     => 'TTLDefaultClient',
		client_secret => 'banana',
		response_type => 'code',
		redirect_uri  => 'https://client/cb',
		state         => 'queasy',
	);

	$t->get_ok( $auth_route => form => \%valid_auth_params )
		->status_is( 302 )
		;

	my $location = Mojo::URL->new( $t->tx->res->headers->location );
	is( $location->path,'/cb','redirect to right place' );
	ok( my $auth_code = $location->query->param( 'code' ),'includes code' );
	is( $location->query->param( 'state' ),'queasy','includes state' );

	my %valid_token_params = (
		client_id     => 'TTLDefaultClient',
		client_secret => 'banana',
		grant_type    => 'authorization_code',
		code          => $auth_code,
		redirect_uri  => $valid_auth_params{redirect_uri},
	);

	$t->post_ok( $token_route => form => \%valid_token_params )
		->status_is( 200 )
		->header_is( 'Cache-Control' => 'no-store' )
		->header_is( 'Pragma'        => 'no-cache' )
		;

	cmp_deeply(
		$t->tx->res->json,
		{
			scopes        => ignore(),
			access_token  => re( '^.+$' ),
			token_type    => 'Bearer',
			expires_in    => 12345,
			refresh_token => re( '^.+$' ),
		},
		'json_is_deeply'
	);

};

done_testing();

# vim: ts=2:sw=2:et
