#!perl

use strict;
use warnings;

package FullFatOAuth;

use Mojo::Base qw( Mojolicious );

sub startup {
  my ( $self ) = @_;

  $self->plugin(
    'OAuth2::Server' => {
      'verify_client'        => sub { return ( 1 ) },
      'login_resource_owner' => sub {
        my ( %args ) = @_;
        my $c = $args{mojo_controller};
        my $uri = join( '?',$c->url_for('current'),$c->url_with->query );
        $c->flash( 'redirect_after_login' => $uri );
        $c->redirect_to( '/oauth/login' );
        return 0;
      },
    }
  );

  $self->routes->any('/oauth/login')
    ->to('Public#login');
}

package FullFatOAuth::Public;

use Mojo::Base 'Mojolicious::Controller';

sub login {
  my ( $self ) = @_;
  $self->render( text => 'login: ' . $self->flash( 'redirect_after_login' ) );
}


package main;

use strict;
use warnings;

use Test::Mojo;
use Test::More;
use Mojolicious::Commands;

my $t = Test::Mojo->new( 'FullFatOAuth' );
$t->ua->max_redirects( 2 );

note( "flash in plugin accesible to controller" );
$t->get_ok( '/oauth/authorize?client_id=1&response_type=code&redirect_uri=foo' )
  ->status_is( 200 )
  ->content_is( 'login: /oauth/authorize?client_id=1&response_type=code&redirect_uri=foo' )
;

done_testing();
