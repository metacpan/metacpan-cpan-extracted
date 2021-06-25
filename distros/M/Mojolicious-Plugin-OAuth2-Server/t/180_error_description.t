#!perl

use strict;
use warnings;

use Mojo::URL;
use Mojolicious::Lite;
use Test::More;
use Test::Mojo;
use Test::Deep;


my $verify_client_sub = sub {
	my ( %args ) = @_;

	my ( $c,$client_id,$scopes_ref,$redirect_uri,$response_type )
		= @args{ qw/ mojo_controller client_id scopes redirect_uri response_type / };

	return ( 0,'unauthorized_client','unknown client error message' ) if $client_id ne 'TestClient';
	return ( 1,undef ); # all good
};

my $verify_auth_code_sub = sub {
	my ( %args ) = @_;

	my ( $c,$client_id,$client_secret,$auth_code,$uri )
		= @args{qw/ mojo_controller client_id client_secret auth_code redirect_uri / };

	return ( 0,'something_whatever',undef,undef,'something whatever error message' );
};

MOJO_APP: {
	# plugin configuration
	plugin 'OAuth2::Server' => {
		auth_code_ttl    => 3600,
		access_token_ttl => 3600,
		verify_client    => $verify_client_sub,
		verify_auth_code => $verify_auth_code_sub,
		clients          => {
			TestClient => {
				client_secret => 'boo',
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

my $auth_code; # used later for access token checks
my %valid_auth_params = (
	client_id     => 'TestClient',
	client_secret => 'boo',
	response_type => 'code',
	redirect_uri  => 'https://client/cb',
	state         => 'queasy',
);

subtest 'custom error_description on invalid request' => sub {

	subtest 'valid client' => sub {

		$t->get_ok( $auth_route => form => \%valid_auth_params )
			->status_is( 302 )
			;

		my $location = Mojo::URL->new( $t->tx->res->headers->location );
		is( $location->path,'/cb','redirect to right place' );
		ok( $auth_code = $location->query->param( 'code' ),'includes code' );
		is( $location->query->param( 'state' ),'queasy','includes state' );

	};

	subtest 'invalid client' => sub {

		my %invalid_auth_params = (
			%valid_auth_params,
			client_id => 'UNKNOWN',
		);

		$t->get_ok( $auth_route => form => \%invalid_auth_params )
			->status_is( 302 )
			;

		my $location = Mojo::URL->new( $t->tx->res->headers->location );

		is( $location->path,'/cb','redirect to right place' );
		ok( my $error = $location->query->param( 'error' ),'includes error' );
		ok( my $error_description = $location->query->param( 'error_description' ),'includes error_description' );

		is $error, 'unauthorized_client', 'got expected error';
		is $error_description, 'unknown client error message', 'got expected error description';

	};

};

subtest 'custom error_description in token JSON response' => sub {

	my %valid_token_params = (
		client_id     => 'TestClient',
		client_secret => 'boo',
		grant_type    => 'authorization_code',
		code          => $auth_code,
		redirect_uri  => $valid_auth_params{redirect_uri},
	);

	$t->post_ok( $token_route => form => \%valid_token_params )
		->status_is( 400 )
		;

	cmp_deeply(
		$t->tx->res->json,
		{
			'error' => 'something_whatever',
			'error_description' => 'something whatever error message',
		},
		'got expected error description'
	);

};

done_testing();

# vim: ts=2:sw=2:et
