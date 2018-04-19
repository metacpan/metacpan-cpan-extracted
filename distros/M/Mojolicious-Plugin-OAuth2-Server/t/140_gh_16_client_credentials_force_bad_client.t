#!perl

use strict;
use warnings;

use Mojolicious::Lite;
use Test::More;
use FindBin qw/ $Bin /;
use Mojo::Util qw/ b64_encode /;
use lib $Bin;
use AllTests;

my $verify_client_sub = sub {
  return ( 0,'unauthorized_client' );
};

my $token_route = '/o/token';

MOJO_APP: {
  # plugin configuration
  plugin 'OAuth2::Server' => {
    args_as_hash        => 0,
    access_token_route  => $token_route,
    verify_client       => $verify_client_sub,
    jwt_secret          => 'eio',
    jwt_claims          => sub { return ( iss => "https://localhost:5001" ) },
  };

  group {
    # /api - must be authorized
    under '/api' => sub {
      my ( $c ) = @_;
      return 1 if $c->oauth && $c->oauth->{client_id};
      $c->render( status => 401, text => 'Unauthorized' );
      return undef;
    };

    get '/eat' => sub { shift->render( text => "food"); };
  };

  # /sleep - must be authorized and have sleep scope
  get '/api/sleep' => sub {
    my ( $c ) = @_;
    $c->oauth( 'sleep' )
      || $c->render( status => 401, text => 'You cannot sleep' );

    $c->render( text => "bed" );
  };
};

my $t = AllTests::run({
  access_token_route => $token_route,
  grant_type         => 'client_credentials',
  skip_revoke_tests  => 1, # there is no auth code
  no_200_responses   => 1,
});


# posting 
$t->post_ok(
	$token_route => {
		Authorization => ( "Basic " . b64_encode( join( ':',2,'wrong' ),'' ) )
	} => form => {
		grant_type => 'client_credentials',
	}
)
	->status_isnt( 200 )
;

is(
	$t->tx->res->json->{error},
	'invalid_request',
	'trying to get token gives error'
);

done_testing();

# vim: ts=2:sw=2:et
