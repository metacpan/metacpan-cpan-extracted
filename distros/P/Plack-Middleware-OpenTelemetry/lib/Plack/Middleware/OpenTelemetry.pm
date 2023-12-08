package Plack::Middleware::OpenTelemetry;
$Plack::Middleware::OpenTelemetry::VERSION = '0.233360';
# ABSTRACT: Plack middleware to setup OpenTelemetry tracing

use v5.36.0;
use strict;
use warnings;
use feature 'signatures';
use parent qw(Plack::Middleware);
use Plack::Util::Accessor qw(resource_attributes);
use OpenTelemetry -all;
use OpenTelemetry::Constants qw( SPAN_KIND_SERVER SPAN_STATUS_ERROR SPAN_STATUS_OK );
use OpenTelemetry::Common 'config';
use Syntax::Keyword::Dynamically;
use Feature::Compat::Try;
use URI;

sub prepare_app {
    my $self = shift;
}

sub call {
    my ($self, $env) = @_;

    my $tracer =
      otel_tracer_provider->tracer(schema_url => 'https://opentelemetry.io/schemas/1.21.0');

    my $method = $env->{REQUEST_METHOD};
    my $scheme = $env->{HTTP_X_FORWARDED_PROTO} || $env->{"psgi.url_scheme"};
    my $url    = URI->new($scheme . '://' . $env->{HTTP_HOST} . $env->{REQUEST_URI});

    my $context = otel_propagator->extract(
        $env, undef,
        sub ($carrier, $key) {
            $carrier->{'HTTP_' . uc $key};
        },
    );

    my $resource;
    if (my $a = $self->resource_attributes) {
        my $resource = OpenTelemetry::SDK::Resource->new()
          ->merge(OpenTelemetry::SDK::Resource->new(empty => 1, attributes => $a));
    }

    my $span = $tracer->create_span(
        name => "$method request",

        ($resource ? (resource => $resource) : ()),

        parent     => $context,
        kind       => SPAN_KIND_SERVER,
        attributes => {
            "plack.version" => "$Plack::VERSION",

            # https://opentelemetry.io/docs/specs/semconv/http/http-spans/
            "client.address"      => $env->{REMOTE_ADDR},
            "http.request.method" => $method,
            "user_agent.original" => $env->{HTTP_USER_AGENT},
            "server.address"      => $env->{HTTP_HOST},
            "url.full"            => $url->as_string,
            "url.scheme"          => $scheme,
            "url.path"            => $url->path,
            ($url->query ? ("url.query" => $url->query) : ()),

            # todo: "http.request_content_length"

        },
    );

    $context = otel_context_with_span($span, $context);
    dynamically otel_current_context = $context;

    try {
        my $res = eval { $self->app->($env) };

        if ($@) {
            warn "request returned: $@";
            die $@;
        }

        if (ref($res) && ref($res) eq 'ARRAY') {
            set_status_code($span, $res);
            my $content_length = Plack::Util::content_length($res->[2]);
            $span->set_attribute("http.response_content_length", $content_length);
            $span->end();
            return $res;
        }

        return $self->response_cb(
            $res,
            sub {
                my $res = shift;
                set_status_code($span, $res);
                my $content_length = Plack::Util::content_length($res->[2]);
                $span->set_attribute("http.response_content_length", $content_length);
                $span->set_attribute("plack.callback",               "true");
                $span->end();
            }
        );
    }
    catch ($error) {
        warn "got request error: $error";
        my $message = $error;
        $span->record_exception($error)->set_attribute('http.status_code' => 500)
          ->set_status(SPAN_STATUS_ERROR, $message)->end;
        die $error;
    }
}

sub set_status_code ($span, $res) {
    my $status_code = $res->[0] or return;
    $span->set_attribute("http.response.status_code", $status_code);
    if ($status_code >= 400 and $status_code <= 599) {
        $span->set_status(SPAN_STATUS_ERROR);
    }
    elsif ($status_code >= 200 and $status_code <= 399) {
        $span->set_status(SPAN_STATUS_OK);
    }
}

1;

=head1 NAME

Plack::Middleware::OpenTelemetry - Plack middleware to handle X-Forwarded-For headers

=head1 VERSION

version 0.233360

=head1 SYNOPSIS

  builder {
    enable "Plack::Middleware::OpenTelemetry",
      tracer => {name => "my-app", "version" => "1.2"};
  };

=head1 DESCRIPTION

C<Plack::Middleware::OpenTelemetry> will setup an C<OpenTelemetry>
span for the request.

=head1 PARAMETERS

=over

=item resource_attributes

Optional attributes to be added to the resource in the created spans.

=back

=head1 NOTES

The L<Net::Async::HTTP::Server> plackup server is recommended:
C<plackup -s Net::Async::HTTP::Server>

=head1 SEE ALSO

L<Plack::Middleware>, L<OpenTelemetry::SDK>

=head1 AUTHOR

Ask Bjørn Hansen <ask@develooper.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2023 by Ask Bjørn Hansen.

This is free software; you can redistribute it and/or modify it under
the MIT software license.

=cut
