package MyApp;
use Mojo::Base 'Mojolicious';

sub startup {
  my $self = shift;

  my %am_cfg = ( skip_mods => [qw/Fake/] );

  $self->plugin( 'AdvancedMod', %am_cfg );

  $self->configurator( file => 't/etc/general.yml', include => 1 );

  my $r = $self->routes;
  $r->namespaces( [ 'MyApp::Controllers', 'MyApp::Controllers::App' ] );

  $r->get( '/' )->to( 'app#index' );
  $r->get( '/show' )->to( 'app#show' );
  $r->get( '/params' )->to( 'app#params' );

  $self->action_filter(
    is_auth => sub {
      my $me = shift;
      $me->render( text => "is_auth filter" );
    },
    check_permissions => sub {
      my $me = shift;
      $me->render( text => "check_permissions filter" );
    },
  );

}

1;