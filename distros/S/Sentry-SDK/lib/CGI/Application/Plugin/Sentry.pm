package CGI::Application::Plugin::Sentry;
use Mojo::Base -base, -signatures;

use CGI::Application;
use Mojo::Util 'dumper';
use Sentry::SDK;

CGI::Application->add_callback(
  init => sub ($c, %) {
    Sentry::SDK->init(
      { dsn => 'fixme', release => '1.0.0', dist => '12345', });
  }
);

CGI::Application->add_callback(
  error => sub ($c, $error) {
    Sentry::SDK->capture_exception($error);
  }
);

CGI::Application->add_callback(
  prerun => sub ($c, $rm) {
    Sentry::Hub->get_current_hub()->push_scope();

    my $transaction = Sentry::SDK->start_transaction(
      { name => $rm, op => 'http.server', },
      {
        request => {
          url     => $c->query->url(-full => 1),
          method  => $c->query->request_method,
          query   => { $c->query->Vars },
          headers => { map { $_ => $c->query->http($_) } $c->query->http },
          env     => \%ENV,
        }
      }
    );

    $c->param('__sentry__transaction', $transaction);

    Sentry::SDK->configure_scope(sub ($scope) {
      $scope->set_span($transaction);
    });
  }
);

CGI::Application->add_callback(
  postrun => sub ($c, $body_ref) {
    my $transaction = $c->param('__sentry__transaction');
    $transaction->set_http_status(200);    # FIXME
    $transaction->finish();
  }
);

CGI::Application->add_callback(
  teardown => sub ($c) {
    Sentry::Hub->get_current_hub()->pop_scope();
  }
);

1;
