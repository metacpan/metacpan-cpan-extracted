package
     ApiTest::Controller::Auth;
use Mojo::Base 'Mojolicious::Controller';

# This action will render a template
sub test {
  my $self = shift;

  # Render template "example/welcome.html.ep" with message
  return 1;
}

1;

