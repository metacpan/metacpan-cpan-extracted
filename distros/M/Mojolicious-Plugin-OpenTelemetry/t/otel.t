#!/usr/bin/env perl

use Test2::V0;
use Test2::Tools::Spec;
use Test2::MojoX;

use Mojo::Base -strict, -signatures;
use Feature::Compat::Try;
use Mojolicious;

use OpenTelemetry -all;
use OpenTelemetry::Constants -span;
use OpenTelemetry::Trace::Tracer;

my $span;
my $mock = mock 'OpenTelemetry::Trace::Tracer' => override => [
    create_span => sub {
        shift;
        $span = mock { otel => { @_ } } => add => [
            record_exception => sub ($self, $exception) {
              $self->{otel}{exception} = $exception;
              return $self;
            },
            set_name => sub ($self, $name) {
              $self->{otel}{name} = $name;
              return $self;
            },
            set_attribute    => sub( $self, %attrs ) {
              $self->{otel}{attributes} = { %{$self->{otel}{attributes} // {}}, %attrs };
              return $self;
            },
            set_status => sub ($self, $status, $message) {
              $self->{otel}{status} = [ $status, $message ];
              return $self;
            },
            end => sub ($self) {
              $self->{end}++;
              return $self;
            },
            context => sub ($self) {
              return $self->{context} //= OpenTelemetry::Trace::SpanContext->new;
            }
        ];
    },
];

use Object::Pad;
class Local::Provider :isa(OpenTelemetry::Trace::TracerProvider) { }
OpenTelemetry->tracer_provider = Local::Provider->new;

sub init_app {
    $span = undef;
    my $app = Mojolicious->new;
    $app->plugin('Mojolicious::Plugin::OpenTelemetry');
    my $t = Test2::MojoX->new( $app );
    return $t;
}

describe 'incoming HTTP request' => sub {
    tests 'basic request' => sub {
        my $t = init_app();
        $t->app->routes->get('/rte')->to( cb => sub( $c ) {
            $c->render( status => 200, json => {} )
        });

        $t->get_ok('/rte')->status_is(200);

        like $span->{otel}, {
            attributes => {
                'client.address'            => '127.0.0.1',
                'client.port'               => T,
                'http.request.method'       => 'GET',
                'http.route'                => '/rte',
                'http.response.status_code' => 200,
                'network.protocol.version'  => '1.1',
                'server.address'            => '127.0.0.1',
                'server.port'               => T,
                'url.path'                  => '/rte',
                'url.scheme'                => 'http',
                'user_agent.original'       => 'Mojolicious (Perl)',
            },
            kind => SPAN_KIND_SERVER,
            name => 'GET /rte',
        }, 'span attributes are correct';
    };

    describe 'host / port parsing' => sub {
        my $port;

        case 'With port'    => sub { $port = '1234' };
        case 'Without port' => sub { undef $port    };

        my $t = init_app();
        $t->app->routes->get('/static/url', sub ( $c, @ ) {
          $c->render( text => 'OK' ) });

        tests Host => sub {
            $t->get_ok(
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
            $t->get_ok(
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
            $t->get_ok(
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
            $t->get_ok(
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
};

describe 'Mojo::Log and related' => sub {
    tests 'sets request ID' => sub {
        my $t = init_app();
        my $message = 'Informational';

        my @logs;
        $t->app->log->level('info');
        $t->app->log->on( message => sub ($, @args) {
            push @logs, \@args;
        });

        $t->app->routes->get('/rte')->to( cb => sub( $c ) {
            $c->log->info($message);
            $c->render( status => 200, json => {} );
        });

        $t->get_ok('/rte')->status_is(200);

        my $span_id = $span->context->hex_span_id;
        is \@logs => bag {
            item [ 'info', "[$span_id]", $message ];
        } => 'log contains span ID';
    };
};

describe 'routes' => sub {
    tests 'route with callback' => sub {
        my $t = init_app();
        $t->app->routes->get('/rte', sub( $c ) { $c->render( status => 200, json => {} ) });
        $t->get_ok('/rte')->status_is(200);

        like $span->{otel}, {
            attributes => {
                'http.route' => '/rte',
                'http.response.status_code' => 200,
            },
            name => 'GET /rte',
        }, 'span attributes are correct';
    };

    tests 'route with placeholder' => sub {
        my $t = init_app();
        $t->app->routes->get('/rte/:welcome', sub( $c ) { $c->render( status => 200, json => {} ) });
        $t->get_ok('/rte/Hello')->status_is(200);

        like $span->{otel}, {
            attributes => {
                'http.route' => '/rte/:welcome',
                'http.response.status_code' => 200,
                'url.path' => '/rte/Hello',
            },
            name => 'GET /rte/:welcome',
        }, 'span attributes are correct';
    };

    tests 'Root route is handled correctly' => sub {
        my $t = init_app();
        $t->app->routes->get('/')->to( cb => sub( $c ) { $c->render( status => 200, json => {} ) });
        $t->get_ok('/')->status_is(200);

        like $span->{otel}, {
            attributes => {
                'http.route'                => '/',
                'http.response.status_code' => 200,
                'url.path'                  => '/',
            },
            name => 'GET /',
        }, 'span attributes are correct';
    };

    tests 'nested routes' => sub {
        my $t = init_app();
        $t->app->routes->under('/private', sub ($c) {
            $c->render(status => 401, json => {});
            return 0;
        })->get('/admin')->to(
            cb => sub( $c ) {
                $c->render( status => 200, json => {} );
            },
        );
        $t->get_ok('/private/admin')->status_is(401);

        like $span->{otel}, {
            attributes => {
                'http.route'                => '/private/admin',
                'http.response.status_code' => 401,
                'url.path'                  => '/private/admin',
            },
            name => 'GET /private/admin',
        }, 'span attributes are correct';
    };
};

describe 'end()' => sub {
    tests 'delayed rendering with returned promise' => sub {
        my $t = init_app();
        $t->app->routes->get('/delayed', sub( $c ) {
            $c->render_later;
            return Mojo::Promise->new( sub ($resolve, $reject) {
                Mojo::IOLoop->next_tick(sub {
                    $c->render( status => 200, json => {} );
                    $resolve->();
                });
            })
        });
        $t->get_ok('/delayed')->status_is(200);
        is $span->{end}, 1, 'span is marked finished';
    };

    tests 'delayed rendering with no promise' => sub {
        my $t = init_app();
        $t->app->routes->get('/delayed', sub( $c ) {
            Mojo::IOLoop->next_tick(sub {
                $c->render( status => 200, json => {} );
            });
            $c->render_later;
        });
        $t->get_ok('/delayed')->status_is(200);
        is $span->{end}, 1, 'span is marked finished';
    };

    tests 'exception handling' => sub {
        my $t = init_app();
        $t->app->routes->get('/error', sub( $c ) {
            die "Error";
        });
        $t->get_ok('/error')->status_is(500);
        is $span->{end}, 1, 'span is marked finished';
    };

    tests 'delayed exception handling with promise' => sub {
        my $t = init_app();
        $t->app->routes->get('/error', sub( $c ) {
            $c->render_later;
            return Mojo::Promise->new( sub ($resolve, $reject) {
                Mojo::IOLoop->next_tick(sub {
                    $reject->('error');
                });
            })
        });
        $t->get_ok('/error')->status_is(500);
        is $span->{end}, 1, 'span is marked finished';
    };

    tests 'delayed exception handling without promise' => sub {
        # There's not much we can do on this one
        my $t = init_app();
        $t->app->routes->get('/error', sub( $c ) {
            $c->render_later;
            $c->inactivity_timeout(0.1);
            Mojo::IOLoop->next_tick(sub {
                die 'error';
            });
        });

        try { $t->ua->get('/error') }
        catch ($e) {}

        is $span->{end}, 1, 'span is marked finished';
    };
};

done_testing;
