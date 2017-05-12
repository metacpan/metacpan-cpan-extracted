package Rex::JobControl::Dashboard;
$Rex::JobControl::Dashboard::VERSION = '0.18.0';
use Mojo::Base 'Mojolicious::Controller';

sub check_login {
  my ($self) = @_;
  $self->stash( is_logged_in => $self->is_user_authenticated );
  $self->redirect_to("/login") and return 0
    unless ( $self->is_user_authenticated );
  return 1;
}

sub login {
  my $self = shift;
  $self->render;
}

sub login_post {
  my $self = shift;

  if (
    $self->authenticate( $self->param("username"), $self->param("password") ) )
  {
    $self->redirect_to("/");
  }
  else {
    $self->flash(
      {
        title   => "Authentication failed.",
        message => "Username or password may be wrong.",
      }
    );

    $self->redirect_to("/login");
  }
}

sub ctrl_logout {
  my $self = shift;
  $self->logout;
  $self->redirect_to("/");
}

sub prepare_stash {
  my $self = shift;

  my @projects;

  opendir( my $dh, $self->config->{project_path} ) or die($!);
  while ( my $entry = readdir($dh) ) {
    next if ( !-f $self->config->{project_path} . "/$entry/project.conf.yml" );
    push @projects, $self->project($entry);
  }
  closedir($dh);

  $self->stash( project_count => scalar(@projects) );
  $self->stash( projects      => \@projects );
}

sub index {
  my $self = shift;
  $self->render;
}

1;
