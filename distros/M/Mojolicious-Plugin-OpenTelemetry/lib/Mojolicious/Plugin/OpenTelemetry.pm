package Mojolicious::Plugin::OpenTelemetry;
# ABSTRACT: An OpenTelemetry integration for Mojolicious

our $VERSION = '0.003';

use Mojo::Base 'Mojolicious::Plugin', -signatures;

use Feature::Compat::Try;
use OpenTelemetry -all;
use OpenTelemetry::Constants -span;
use Syntax::Keyword::Dynamically;

sub register ( $, $app, $config, @ ) {
    $config->{tracer}{name} //= otel_config('SERVICE_NAME') // $app->moniker;

    $app->hook( around_action  => sub ( $next, $c, $action, $last, @ ) {
        return unless $last;

        my $tracer = otel_tracer_provider->tracer( %{ $config->{tracer} } );

        my $tx      = $c->tx;
        my $req     = $tx->req;
        my $url     = $req->url;
        my $route   = $c->match->endpoint->to_string;
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
            name       => $method . ' ' . $route,
            kind       => SPAN_KIND_SERVER,
            parent     => $context,
            attributes => {
                'http.request.method'            => $method,
                'network.protocol.version'       => $req->version,
                'url.path'                       => $url->path->to_string,
                'url.scheme'                     => $url->scheme,
                'http.route'                     => $route,
                'client.address'                 => $tx->remote_address,
                'client.port'                    => $tx->remote_port,
                $host  ? ( 'server.address'      => $host  ) : (),
                $port  ? ( 'server.port'         => $port  ) : (),
                $agent ? ( 'user_agent.original' => $agent ) : (),
                $query ? ( 'url.query'           => $query ) : (),
            },
        );

        dynamically otel_current_context
            = otel_context_with_span( $span, $context );

        try {
            my @result;
            my $want = wantarray;

            if ($want) { @result    = $next->() }
            else       { $result[0] = $next->() }

            my $promise = $result[0]->can('then')
                ? $result[0]
                : Mojo::Promise->resolve(1);

            $promise->then( sub {
                my $code  = $tx->res->code;

                # The status of server spans must be left unset if the
                # response is a 4XX error
                # See https://github.com/open-telemetry/semantic-conventions/blob/main/docs/http/http-spans.md#status
                if ( $code >= 500 ) {
                    $span->set_status(SPAN_STATUS_ERROR);
                }

                $span
                    ->set_attribute( 'http.response.status_code' => $code )
                    ->end;
            })->wait;

            return $want ? @result : $result[0];
        }
        catch ($error) {
            my ($message) = split /\n/, "$error", 2;
            $message =~ s/ at \S+ line \d+\.$//a;

            $span
                ->record_exception($error)
                ->set_status( SPAN_STATUS_ERROR, $message )
                ->set_attribute(
                    'error.type' => ref $error || 'string',
                    'http.response.status_code' => 500,
                )
                ->end;

            die $error;
        }
    });
}

1;
