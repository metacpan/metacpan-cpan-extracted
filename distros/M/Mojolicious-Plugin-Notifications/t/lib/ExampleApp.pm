package ExampleApp;
use Mojo::Base 'Mojolicious';

sub startup {
  my $self = shift;

  # Client notifications
  $self->plugin(Notifications => {
    'ExampleApp::Plugin::MyEngine' => 1,
    JSON => 1,
    HTML => 1
  });

  my $r = $self->routes;
  $r->get('/error')->to('Check#resp');
};

1;
