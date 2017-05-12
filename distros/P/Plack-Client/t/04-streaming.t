#!/usr/bin/env perl
use strict;
use warnings;
use lib 't/lib';
use Test::More;
use Plack::Client::Test;

use HTTP::Message::PSGI;

my $app = sub {
    my $env = shift;
    return sub {
        my $cb = shift;
        my $w = $cb->([
            200,
            ['Content-Type' => 'text/plain'],
        ]);
        $w->write($_) for (
                (map { ($env->{$_} || '') . "\n" }
                    qw(
                        REQUEST_METHOD
                        REQUEST_URI
                        CONTENT_LENGTH
                    )),
                (map { ucfirst(lc) . ': ' . $env->{"HTTP_X_$_"} . "\n" }
                    grep { $_ ne 'FORWARDED_FOR' } grep { s/^HTTP_X_// }
                        keys %$env),
                do {
                    my $fh = $env->{'psgi.input'};
                    $fh->read(my $body, $env->{CONTENT_LENGTH});
                    $body;
                },
            );
        $w->close;
    };
};

test_tcp_plackup(
    $app,
    sub {
        my $base_uri = shift;

        test_responses($base_uri, Plack::Client->new(http => {}));
    },
);

{
    my $apps = {
        foo => $app,
    };
    my $base_uri = 'psgi-local://foo';

    test_responses(
        $base_uri,
        Plack::Client->new('psgi-local' => {apps => $apps})
    );
}

sub test_responses {
    my ($base_uri, $client) = @_;
    local $Test::Builder::Level = $Test::Builder::Level + 1;

    response_is(
        $client->get($base_uri),
        200,
        ['Content-Type' => 'text/plain'],
        "GET\n/\n\n"
    );

    response_is(
        $client->get($base_uri . '/'),
        200,
        ['Content-Type' => 'text/plain'],
        "GET\n/\n\n"
    );

    response_is(
        $client->get($base_uri . '/foo'),
        200,
        ['Content-Type' => 'text/plain'],
        "GET\n/foo\n\n"
    );

    response_is(
        $client->get($base_uri . '/foo', ['X-Foo' => 'bar']),
        200,
        ['Content-Type' => 'text/plain'],
        "GET\n/foo\n\nFoo: bar\n"
    );

    response_is(
        $client->get($base_uri . '/foo', HTTP::Headers->new('X-Foo' => 'bar')),
        200,
        ['Content-Type' => 'text/plain'],
        "GET\n/foo\n\nFoo: bar\n"
    );

    response_is(
        $client->post($base_uri, [], "foo"),
        200,
        ['Content-Type' => 'text/plain'],
        "POST\n/\n3\nfoo",
    );

    response_is(
        $client->put($base_uri, [], "foo"),
        200,
        ['Content-Type' => 'text/plain'],
        "PUT\n/\n3\nfoo",
    );

    response_is(
        $client->delete($base_uri),
        200,
        ['Content-Type' => 'text/plain'],
        "DELETE\n/\n\n",
    );

    response_is(
        $client->head($base_uri),
        200,
        ['Content-Type' => 'text/plain'],
        "",
    );

    response_is(
        $client->request(HTTP::Request->new(GET => $base_uri)),
        200,
        ['Content-Type' => 'text/plain'],
        "GET\n/\n\n"
    );

    {
        my $base = URI->new($base_uri);
        my $uri = $base->clone;
        $uri->scheme('http');
        my $env = HTTP::Request->new(GET => $uri)->to_psgi;
        $env->{'plack.client.original_uri'} = $base;
        response_is(
            $client->request($env),
            200,
            ['Content-Type' => 'text/plain'],
            "GET\n/\n\n"
        );
    }

    {
        my $base = URI->new($base_uri);
        my $uri = $base->clone;
        $uri->scheme('http');
        my $env = HTTP::Request->new(GET => $uri)->to_psgi;
        $env->{'plack.client.original_uri'} = $base;
        response_is(
            $client->request(Plack::Request->new($env)),
            200,
            ['Content-Type' => 'text/plain'],
            "GET\n/\n\n"
        );
    }
}

done_testing;
