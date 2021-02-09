package Sentry::Integration::LwpUserAgent;
use Mojo::Base 'Sentry::Integration::Base', -signatures;

use Mojo::Util qw(dumper);
use Sentry::Util 'around';

has breadcrumbs => 1;
has tracing     => 1;

sub setup_once ($self, $add_global_event_processor, $get_current_hub) {
  return if (!$self->breadcrumbs && !$self->tracing);

  around(
    'LWP::UserAgent',
    request => sub ($orig, $lwp, $request, @args) {

      my $url = $request->uri;

      # Exclude Requests to the Sentry server
      return $orig->($lwp, $request, @args)
        if $request->header('x-sentry-auth');

      my $hub = $get_current_hub->();
      my $span;

      if ($self->tracing && (my $parent_span = $hub->get_scope()->get_span)) {
        $span = $parent_span->start_child({
          op          => 'http',
          name        => 'My Transaction',
          description => $request->method . ' ' . $request->uri,
          data        => {
            url     => $request->uri,
            method  => $request->method,
            headers => $request->headers,
          },
        });
      }

      my $result = $orig->($lwp, $request, @args);

      $hub->add_breadcrumb({
        type     => 'http',
        category => 'LWP::UserAgent',
        data     => {
          url         => $request->uri,
          method      => $request->method,
          status_code => $result->code,
        }
      })
        if $self->breadcrumbs;

      if ($self->tracing) {

        # $span->set_http_status($tx->res->code);
        $span->finish();
      }

      return $result;
    }
  );
}

1;
