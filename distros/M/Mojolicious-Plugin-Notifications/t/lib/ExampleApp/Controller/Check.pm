package ExampleApp::Controller::Check;
use Mojo::Base 'Mojolicious::Controller';

sub resp {
  my $c = shift;
  $c->notify(error => 'Example');
  return $c->respond_to(
    html => sub {
      shift->render(
        inline => '<p><%= notifications "html" %></p>'
      ),
    },
    json => sub {
      my $c = shift;
      $c->render(
        json => $c->notifications('json')
      )
    }
  );
};

1;
