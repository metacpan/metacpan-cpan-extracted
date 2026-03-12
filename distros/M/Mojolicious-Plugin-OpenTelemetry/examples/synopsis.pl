#!/usr/bin/env perl

BEGIN {
    $ENV{OTEL_TRACES_EXPORTER} //= 'console';
    $ENV{OTEL_PERL_EXPORTER_CONSOLE_FORMAT} //= 'json,pretty=1';
}

use OpenTelemetry::SDK;
use Mojolicious::Lite -signatures;

plugin OpenTelemetry => {
    # Passed to OpenTelemetry::Trace::TracerProvider->tracer
    tracer => {
        name    => 'my_app', # defaults to OTEL_SERVICE_NAME or moniker
        version => '1.234',  # optional
    },
};

# Will generate a span named
# GET /static/url
get '/static/url' => sub ( $c, @ ) {
    $c->render( text => 'OK' );
};

# Will use placeholders for reduced span cardinality
# POST /url/with/:placeholder
post '/url/with/:placeholder' => sub ( $c, @ ) {
    $c->render( text => 'OK' );
};

# Use it also with async actions!
get '/async' => sub ( $c, @ ) {
    $c->ua->get_p('https://httpbin.org/delay/1')
        ->then( sub {
            $c->render( json => shift->result->json );
        });
};

# Errors will be correctly captured in the span
get '/error' => sub ( $c, @ ) {
    die 'oops';
};

# Nested routes should also be captured
under '/private' => sub ($c) {
    $c->render(status => 401, json => {});
    return 0;
};

# Under '/private', so this is '/private/admin'
get '/admin' => sub( $c ) {
    $c->render( status => 200, json => {} );
};

app->start;
