package MyTest::App;
use Mojo::Base 'Mojolicious';
our $VERSION = 1;

sub startup {
  my $self = shift;
  $self->plugin( 'InstallablePaths' );

  $self->routes->any( '/' => sub{
      my $self = shift;

      if ( Mojolicious->VERSION() >= 5.41 ) {
          $self->reply->static('test.html');
      }
      else {
          $self->render_static('test.html');
      }
  });
}

1;

