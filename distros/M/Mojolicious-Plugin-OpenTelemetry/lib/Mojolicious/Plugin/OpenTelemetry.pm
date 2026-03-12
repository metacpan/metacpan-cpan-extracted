package Mojolicious::Plugin::OpenTelemetry;
# ABSTRACT: An OpenTelemetry integration for Mojolicious

our $VERSION = '0.006';

use Mojo::Base 'Mojolicious::Plugin', -signatures;

use Feature::Compat::Try;
use OpenTelemetry -all;
use OpenTelemetry::Constants -span;
use Syntax::Keyword::Dynamically;

sub register ( $, $app, $config, @ ) {
    $config->{tracer}{name} //= otel_config('SERVICE_NAME') // $app->moniker;

    # First, around_dispatch sets up the span and populates what it can
    $app->hook( around_dispatch  => sub ( $next, $c ) {
        my $tracer = otel_tracer_provider->tracer( %{ $config->{tracer} } );

        my $tx      = $c->tx;
        my $req     = $tx->req;
        my $url     = $req->url->to_abs;
        my $query   = $url->query->to_string;
        my $method  = $req->method;
        my $headers = $req->headers;
        my $agent   = $headers->user_agent;

        # https://opentelemetry.io/docs/specs/semconv/http/http-spans/#setting-serveraddress-and-serverport-attributes
        my $hostport;
        if ( my $fwd = $headers->header('forwarded') ) {
            my ($first) = split ',', $fwd, 2;
            $hostport = $1 // $2 if $first =~ /host=(?:"([^"]+)"|([^;]+))/;
        }

        $hostport //= $headers->header('x-forwarded-proto')
            // $headers->header('host');

        my ( $host, $port ) = $hostport =~ /(.*?)(?::([0-9]+))?$/g;

        my $context = otel_propagator->extract(
            $headers,
            undef,
            sub ( $carrier, $key ) { $carrier->header($key) },
        );

        my $span = $tracer->create_span(
            name       => $method,
            kind       => SPAN_KIND_SERVER,
            parent     => $context,
            attributes => {
                'http.request.method'            => $method,
                'network.protocol.version'       => $req->version,
                'url.path'                       => $url->path->to_string,
                'url.scheme'                     => $url->scheme,
                'client.address'                 => $tx->remote_address,
                'client.port'                    => $tx->remote_port,
                $host  ? ( 'server.address'      => $host  ) : (),
                $port  ? ( 'server.port'         => $port  ) : (),
                $agent ? ( 'user_agent.original' => $agent ) : (),
                $query ? ( 'url.query'           => $query ) : (),
            },
        );

        # dynamically works across Future::AsyncAwait boundaries, so we don't need to
        # store the span inside the current Mojolicious controller.
        dynamically otel_current_context
            = otel_context_with_span( $span, $context );

        # Now that we have a new span/context, we can update Mojolicious's data
        # for convenience.
        # This sets the ID that gets logged by the $c->log helper
        $req->request_id( $span->context->hex_span_id );

        # When the transaction is finished, get the response data
        # XXX: For websockets, this will be when the websocket closes, which may not
        # be ideal: It would miss the HTTP handshake 101 response.
        $c->tx->on(finish => sub ($tx) {
          $span->set_attribute('http.response.status_code', $tx->res->code);
          $span->end;
        });

        # around_dispatch handles exceptions
        try {
          $next->();
        }
        catch ($error) {
            my ($message) = split /\n/, "$error", 2;
            $message =~ s/ at \S+ line \d+\.$//a;

            $span
                ->record_exception($error)
                ->set_status( SPAN_STATUS_ERROR, $message )
                ->set_attribute(
                    'error.type' => ref $error || 'string',
                );
            die $error;
        }
    });

    # around_action fills in more attributes, since it now knows what action is being taken
    $app->hook( around_action => sub( $next, $c, $action, $last, @ ) {
        # We don't check $last because this may still be the last action we do.
        # If, for example, an intermediate action throws an exception or otherwise
        # interrupts the dispatch cycle.
        my $tx      = $c->tx;

        # Mojolicious normalizes routes to remove the trailing slash, which is fine
        # until it's the only thing in the route.
        my $route   = $c->match->endpoint->to_string || '/';

        my $span = otel_span_from_context;
        $span->set_name( $tx->req->method . ' ' . $route );
        $span->set_attribute( 'http.route' => $route );

        $next->();
    });
}

1;
