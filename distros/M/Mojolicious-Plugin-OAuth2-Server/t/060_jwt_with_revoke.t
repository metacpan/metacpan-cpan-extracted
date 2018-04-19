#!perl

use strict;
use warnings;

use Mojolicious::Lite;
use Test::More;
use FindBin qw/ $Bin /;
use lib $Bin;
use AllTests;

MOJO_APP: {
  # plugin configuration
  plugin 'OAuth2::Server' => {
    jwt_secret => 'prince edward island potatoes',
    clients              => {
      1 => {
        client_secret => 'boo',
        scopes        => {
          eat       => 1,
          drink     => 0,
          sleep     => 1,
        },
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

AllTests::run({
  skip_revoke_tests => 1,
});

done_testing();

# vim: ts=2:sw=2:et
