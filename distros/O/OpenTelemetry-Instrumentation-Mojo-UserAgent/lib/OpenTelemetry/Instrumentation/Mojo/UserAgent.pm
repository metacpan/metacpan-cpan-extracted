package OpenTelemetry::Instrumentation::Mojo::UserAgent;
# ABSTRACT: OpenTelemetry instrumentation for Mojo::UserAgent

our $VERSION = '0.01';

use strict;
use warnings;
use experimental 'signatures';

use Class::Inspector;
use Class::Method::Modifiers 'install_modifier';
use Feature::Compat::Try;
use List::Util 'none';
use Syntax::Keyword::Dynamically;
use OpenTelemetry::Constants qw(SPAN_KIND_CLIENT SPAN_STATUS_ERROR);
use OpenTelemetry::Context;
use OpenTelemetry::Trace;
use OpenTelemetry;

use parent 'OpenTelemetry::Instrumentation';

sub dependencies {'Mojo::UserAgent'}

my sub get_headers($headers, $want, $prefix) {
    return unless @$want;

    my %attributes;
    for my $name (@{$headers->names}) {
        (my $key = $name) =~ tr/-/_/;
        next if none {$key =~ $_} @$want;
        push @{$attributes{ $prefix . '.' . lc $key } //= []},
            @{$headers->every_header($name)};
    }

    %attributes;
}

my ($original, $loaded);

sub uninstall($class) {
    return unless $loaded;
    no strict 'refs';
    no warnings 'redefine';
    delete $Class::Method::Modifiers::MODIFIER_CACHE{'Mojo::UserAgent'}{start};
    *{'Mojo::UserAgent::start'} = $original;
    undef $loaded;
    return;
}

sub install($class, %config) {
    return if $loaded;
    return unless Class::Inspector->loaded('Mojo::UserAgent');

    my @wanted_request_headers = map qr/^\Q$_\E$/i, map tr/-/_/r,
        @{delete $config{request_headers} // []};

    my @wanted_response_headers = map qr/^\Q$_\E$/i, map tr/-/_/r,
        @{delete $config{response_headers} // []};

    $original = \&Mojo::UserAgent::start;
    install_modifier 'Mojo::UserAgent' => around => start => sub {
        my ($code, $self, $tx, $cb, @rest) = @_;

        my $request = $tx->req;
        my $url = $request->url->clone;
        my $method = $request->method;
        my $length = $request->body_size;

        $url->userinfo('REDACTED:REDACTED') if $url->userinfo;

        my $agent = $self->transactor->name;

        my $span = OpenTelemetry->tracer_provider->tracer(
            name    => __PACKAGE__,
            version => $VERSION,
        )->create_span(
            name       => $method,
            kind       => SPAN_KIND_CLIENT,
            attributes => {
                # As per https://github.com/open-telemetry/semantic-conventions/blob/main/docs/http/http-spans.md
                'http.request.method'      => $method,
                'network.protocol.name'    => 'http',
                'network.protocol.version' => $request->version,
                'network.transport'        => 'tcp',
                'server.address'           => $url->host,
                'server.port'              => $url->port
                    // ($url->protocol eq 'https' ? 443 : 80),
                'url.full'                 => "$url", # redacted

                get_headers(
                    $request->headers,
                    \@wanted_request_headers,
                    'http.request.header',
                ),

                $agent ? ('user_agent.original' => $agent) : (),
                $length ? ('http.request.body.size' => $length) : (),
            },
        );

        my $context = OpenTelemetry::Trace->context_with_span($span);

        OpenTelemetry->propagator->inject(
            $request->headers,
            $context,
            sub {shift->header(@_)},
        );

        # Blocking requests run the entire exchange within this call,
        # so we can localize the context around it. Mojo's own finish
        # callbacks fire inside this scope, so they see our span.
        # Note that the transaction returned by start() is the final
        # one: if any redirects were followed, the transaction we
        # were given has been replaced by then
        unless ($cb) {
            dynamically OpenTelemetry::Context->current = $context;

            try {
                my $result = $self->$code($tx, @rest);
                record_response($span, $result // $tx, \@wanted_response_headers);
                return $result;
            } catch ($error) {
                report_error($span, $error);
                die $error;
            } finally {
                $span->end;
            };
        }

        # Non-blocking requests (including promise-based ones, which
        # call start with an internal callback) report and end the
        # span inside a wrapper around the given callback, restoring
        # the context in case it wants to do more work (eg. more
        # requests, which would then be children of our span)
        my $result;
        try {
            $result = $self->$code($tx, @rest, sub($ua, $finished_tx) {
                dynamically OpenTelemetry::Context->current = $context;

                try {
                    record_response($span, $finished_tx, \@wanted_response_headers);
                    $cb->($ua, $finished_tx);
                } catch ($error) {
                    report_error($span, $error);
                    die $error;
                } finally {
                    $span->end;
                }
            });
        } catch ($error) {
            report_error($span, $error);

            # start died before it could register our wrapper, so
            # nothing else will end this span
            $span->end;
            die $error;
        }
        return $result;
    };

    return $loaded = 1;
}

sub record_response($span, $tx, $wanted) {
    my $response = $tx->res;
    my $code = $response->code;

    my $error = $tx->error;
    if ($error && !defined($error->{code})) {
        my $message = $error->{message} // 'Unknown error';
        $span->record_exception($message);
        $span->set_status(SPAN_STATUS_ERROR, $message);
        return;
    }

    return unless $code;

    $span->set_attribute('http.response.status_code' => $code);

    # Only HTTP transactions can have redirects; WebSocket ones cannot
    if ($tx->can('redirects') && (my $count = scalar @{$tx->redirects // []})) {
        $span->set_attribute('http.resend_count' => $count)
    }

    my $length = $response->body_size;
    $span->set_attribute('http.response.body.size' => $length)
        if $length;

    $span->set_status(SPAN_STATUS_ERROR, $code)
        if $code >= 400;

    $span->set_attribute(
        get_headers(
            $response->headers,
            $wanted,
            'http.response.header',
        ),
    );
}

sub report_error($span, $error) {
    my ($description) = split /\n/, $error =~ s/^\s+|\s+$//gr, 2;
    $description =~ s/ at \S+ line \d+\.$//a;

    $span->record_exception($error);
    $span->set_status(SPAN_STATUS_ERROR, $description);
}

1;
