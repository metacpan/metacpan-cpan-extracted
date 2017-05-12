package MyApp::Controllers::App;
use Mojo::Base 'Mojolicious::Controller';

our $BEFORE_FILTERS = {
  is_auth => [qw/show/]
};

our $AFTER_FILTERS = {
  check_permissions  => [qw/index/],
};

sub show {
  my ( $self, $filter, $action ) = @_;
  $self->render( text => 'show action' );
}

sub index {
  my $self = shift;
  $self->render( text => 'index action' );
}

sub params {
  my $self = shift;
  my $prms = $self->hparams();
  $self->render( text => qq~id:$prms->{id};user:$prms->{api}{user};passwd:$prms->{api}{passwd}~ );
}

1;
