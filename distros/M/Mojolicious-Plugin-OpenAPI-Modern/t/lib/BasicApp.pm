package BasicApp;
use Mojo::Base 'Mojolicious', -signatures;

our ($LAST_VALIDATE_REQUEST_STASH, $LAST_VALIDATE_RESPONSE_RESULT, $LAST_VALIDATE_RESPONSE_STASH);

Class::Method::Modifiers::before('Test::Mojo::_request_ok' => sub {
  undef $LAST_VALIDATE_REQUEST_STASH;
  undef $LAST_VALIDATE_RESPONSE_RESULT;
  undef $LAST_VALIDATE_RESPONSE_STASH;
});

sub startup ($self) {
  $self->plugin('OpenAPI::Modern', $self->config->{openapi});

  my $routes = $self->routes;

  $routes->any('/skip_validate_request' => sub ($c) { $c->render(text => 'ok', format => 'txt') });

  $routes->any('/foo*catchall' => sub ($c) {
    my $result = $c->validate_request;
    $LAST_VALIDATE_REQUEST_STASH = $c->stash('openapi');
    $c->render(
      status => $c->req->query_params->param('status') // ($result ? 200 : 400),
      json => {
        result => $result,
      },
    );
  });

  $self->hook(after_dispatch => sub ($c) {
    $LAST_VALIDATE_RESPONSE_RESULT = $c->validate_response;
    $LAST_VALIDATE_RESPONSE_STASH = $c->stash('openapi');
  });
}

1;
