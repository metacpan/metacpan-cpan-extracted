#!/usr/bin/env perl

use Test2::V0;
use Test2::Tools::Spec;
use Test2::MojoX;
use Mojolicious::Lite -signatures;

use OpenTelemetry -all;
use OpenTelemetry::Constants -span;
use OpenTelemetry::Trace::Tracer;

my $span;
my $mock = mock 'OpenTelemetry::Trace::Tracer' => override => [
    create_span => sub {
        shift;
        $span = mock { otel => { @_ } } => track => 1 => add => [
            record_exception => sub { $_[0] },
            set_attribute    => sub { $_[0] },
            set_status       => sub { $_[0] },
        ];
    },
];

sub span_calls ( $tests, $message = undef ) {
    my @calls;
    while ( my $name = shift @$tests ) {
        push @calls => {
            sub_name => $name,
            args     => [ D, @{ shift @$tests } ],
            sub_ref  => E,
        };
    }

#   use Data::Dumper;
#   diag Dumper [ map $_->{sub_name}, @calls ];
#   diag Dumper [ map $_->{sub_name}, @{ [ mocked $span ]->[0]->call_tracking } ];
#   diag '---';

    is  [ mocked($span) ]->[0]->call_tracking, \@calls,
        $message // 'Called expected methods on span';
}

use Object::Pad;
class Local::Provider :isa(OpenTelemetry::Trace::TracerProvider) { }

OpenTelemetry->tracer_provider = Local::Provider->new;

plugin 'OpenTelemetry';

get '/static/url' => sub ( $c, @ ) {
    $c->render( text => 'OK' );
};

get '/url/with/:placeholder' => sub ( $c, @ ) {
    $c->render( text => 'OK' );
};

get '/async' => sub ( $c, @ ) {
    my $promise = Mojo::Promise->new;
    Mojo::IOLoop->timer( 0.1, sub { $promise->resolve('OK') } );

    $promise->then( sub {
        $c->render( text => shift );
    });
};

get '/status/:code' => sub ( $c, @ ) {
    $c->render( text => 'OK', status => $c->stash('code') );
};

get '/error' => sub ( $c, @ ) {
    die 'oops';
};

my $tst = Test2::MojoX->new;

subtest 'Static URL' => sub {
    $tst->get_ok('/static/url?query=parameter')
        ->content_is('OK')
        ->status_is(200);

    is $span->{otel}, {
        attributes => {
            'client.address'           => '127.0.0.1',
            'client.port'              => T,
            'http.request.method'      => 'GET',
            'http.route'               => '/static/url',
            'network.protocol.version' => '1.1',
            'server.address'           => '127.0.0.1',
            'server.port'              => T,
            'url.path'                 => '/static/url',
            'url.query'                => 'query=parameter',
            'url.scheme'               => U,
            'user_agent.original'      => 'Mojolicious (Perl)',
        },
        kind => SPAN_KIND_SERVER,
        name => 'GET /static/url',
        parent => D, # FIXME: cannot use an object check on 5.32?
      # parent => object {
      #     prop isa => 'OpenTelemetry::Context';
      # },
    };

    span_calls [
        set_status    => [ SPAN_STATUS_OK ],
        set_attribute => [ 'http.response.status_code', 200 ],
        end           => [],
    ];
};

subtest 'Async' => sub {
    $tst->get_ok('/async')
        ->content_is('OK')
        ->status_is(200);

    is $span->{otel}, {
        attributes => {
            'client.address'           => '127.0.0.1',
            'client.port'              => T,
            'http.request.method'      => 'GET',
            'http.route'               => '/async',
            'network.protocol.version' => '1.1',
            'server.address'           => '127.0.0.1',
            'server.port'              => T,
            'url.path'                 => '/async',
            'url.scheme'               => U,
            'user_agent.original'      => 'Mojolicious (Perl)',
        },
        kind => SPAN_KIND_SERVER,
        name => 'GET /async',
        parent => D, # FIXME: cannot use an object check on 5.32?
      # parent => object {
      #     prop isa => 'OpenTelemetry::Context';
      # },
    };

    span_calls [
        set_status    => [ SPAN_STATUS_OK ],
        set_attribute => [ 'http.response.status_code', 200 ],
        end           => [],
    ];
};

subtest 'With placeholder' => sub {
    $tst->get_ok('/url/with/value')
        ->content_is('OK')
        ->status_is(200);

    is $span->{otel}, {
        attributes => {
            'client.address'           => '127.0.0.1',
            'client.port'              => T,
            'http.request.method'      => 'GET',
            'http.route'               => '/url/with/:placeholder',
            'network.protocol.version' => '1.1',
            'server.address'           => '127.0.0.1',
            'server.port'              => T,
            'url.path'                 => '/url/with/value',
            'url.scheme'               => U,
            'user_agent.original'      => 'Mojolicious (Perl)',
        },
        kind => SPAN_KIND_SERVER,
        name => 'GET /url/with/:placeholder',
        parent => D, # FIXME: cannot use an object check on 5.32?
      # parent => object {
      #     prop isa => 'OpenTelemetry::Context';
      # },
    };

    span_calls [
        set_status    => [ SPAN_STATUS_OK ],
        set_attribute => [ 'http.response.status_code', 200 ],
        end           => [],
    ];
};

subtest Error => sub {
    $tst->get_ok('/error')
        ->status_is(500);

    is $span->{otel}, {
        attributes => {
            'client.address'           => '127.0.0.1',
            'client.port'              => T,
            'http.request.method'      => 'GET',
            'http.route'               => '/error',
            'network.protocol.version' => '1.1',
            'server.address'           => '127.0.0.1',
            'server.port'              => T,
            'url.path'                 => '/error',
            'url.scheme'               => U,
            'user_agent.original'      => 'Mojolicious (Perl)',
        },
        kind => SPAN_KIND_SERVER,
        name => 'GET /error',
        parent => D, # FIXME: cannot use an object check on 5.32?
      # parent => object {
      #     prop isa => 'OpenTelemetry::Context';
      # },
    };

    span_calls [
        record_exception => [ object { prop isa => 'Mojo::Exception' } ],
        set_status       => [ SPAN_STATUS_ERROR, 'oops' ],
        set_attribute    => [
            'error.type' => 'Mojo::Exception',
            'http.response.status_code' => 500,
        ],
        end => [],
    ];
};

subtest 'Response codes' => sub {
    $tst->get_ok('/status/400')
        ->status_is(400);

    is $span->{otel}, {
        attributes => {
            'client.address'           => '127.0.0.1',
            'client.port'              => T,
            'http.request.method'      => 'GET',
            'http.route'               => '/status/:code',
            'network.protocol.version' => '1.1',
            'server.address'           => '127.0.0.1',
            'server.port'              => T,
            'url.path'                 => '/status/400',
            'url.scheme'               => U,
            'user_agent.original'      => 'Mojolicious (Perl)',
        },
        kind => SPAN_KIND_SERVER,
        name => 'GET /status/:code',
        parent => D, # FIXME: cannot use an object check on 5.32?
      # parent => object {
      #     prop isa => 'OpenTelemetry::Context';
      # },
    };

    span_calls [
        set_attribute    => [ 'http.response.status_code', 400 ],
        end              => [],
    ];
};

describe 'Host / port parsing' => sub {
    my $port;

    case 'With port'    => sub { $port = '1234' };
    case 'Without port' => sub { undef $port    };

    tests Host => sub {
        $tst->get_ok(
            '/static/url' => {
                Host => join ':', 'some.doma.in', $port // (),
            }
        );

        like $span->{otel}, {
            attributes => {
                'server.address' => 'some.doma.in',
                'server.port'    => $port ? $port : DNE,
            },
        };
    };

    tests 'X-Forwarded-Proto wins over Host' => sub {
        $tst->get_ok(
            '/static/url' => {
                Host => 'wrong.doma.in:9999',
                'X-Forwarded-Proto' => join ':', 'some.doma.in', $port // (),
            }
        );

        like $span->{otel}, {
            attributes => {
                'server.address' => 'some.doma.in',
                'server.port'    => $port ? $port : DNE,
            },
        };
    };

    tests 'Forwarded wins over X-Forwarded-Proto' => sub {
        $tst->get_ok(
            '/static/url' => {
                Host      => 'wrong.doma.in:9999',
                'X-Forwarded-Proto' => 'another.wrong.doma.in:8888',
                Forwarded => 'host=' . join ':', 'some.doma.in', $port // (),
            }
        );

        like $span->{otel}, {
            attributes => {
                'server.address' => 'some.doma.in',
                'server.port'    => $port ? $port : DNE,
            },
        };
    };

    tests 'Forwarded with multiple values' => sub {
        $tst->get_ok(
            '/static/url' => {
                Host      => 'wrong.doma.in:9999',
                'X-Forwarded-Proto' => 'another.wrong.doma.in:8888',
                Forwarded => 'host=' . join( ':', 'some.doma.in', $port // () )
                    . ', host=wrong.doma.in:777',
            }
        );

        like $span->{otel}, {
            attributes => {
                'server.address' => 'some.doma.in',
                'server.port'    => $port ? $port : DNE,
            },
        };
    };
};

done_testing;
