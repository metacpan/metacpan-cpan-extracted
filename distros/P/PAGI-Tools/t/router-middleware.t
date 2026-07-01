#!/usr/bin/env perl

use strict;
use warnings;
use Test2::V0;
use Future::AsyncAwait;

use lib 'lib';
use PAGI::App::Router;

# Helper to create a simple async app
sub make_app {
    my ($name, $tracker) = @_;
    return async sub {
        my ($scope, $receive, $send) = @_;
        push @$tracker, "app:$name" if $tracker;
        await $send->({
            type    => 'http.response.start',
            status  => 200,
            headers => [['content-type', 'text/plain']],
        });
        await $send->({
            type => 'http.response.body',
            body => "Hello from $name",
            more => 0,
        });
    };
}

# Helper to simulate a request
async sub request {
    my ($app, %opts) = @_;
    my $scope = {
        type    => $opts{type} // 'http',
        method  => $opts{method} // 'GET',
        path    => $opts{path} // '/',
        headers => $opts{headers} // [],
    };

    my @events;
    my $send = async sub {
        my ($event) = @_;
        push @events, $event;
    };

    my $receive = async sub {
        return { type => 'http.request', body => '', more => 0 };
    };

    await $app->($scope, $receive, $send);
    return \@events;
}

subtest 'backward compatibility - route without middleware' => sub {
    my $router = PAGI::App::Router->new;
    my @tracker;

    $router->get('/' => make_app('home', \@tracker));

    my $app = $router->to_app;
    my $events = request($app, path => '/')->get;

    is \@tracker, ['app:home'], 'app was called';
    is $events->[0]{status}, 200, 'got 200 response';
};

subtest 'single coderef middleware' => sub {
    my $router = PAGI::App::Router->new;
    my @tracker;

    my $mw = sub {
        my ($app) = @_;
        async sub {
            my ($scope, $receive, $send) = @_;
            push @tracker, 'mw:before';
            await $app->($scope, $receive, $send);
            push @tracker, 'mw:after';
        };
    };

    $router->get('/' => [$mw] => make_app('home', \@tracker));

    my $app = $router->to_app;
    my $events = request($app, path => '/')->get;

    is \@tracker, ['mw:before', 'app:home', 'mw:after'], 'correct execution order';
    is $events->[0]{status}, 200, 'got 200 response';
};

subtest 'multiple middleware execution order' => sub {
    my $router = PAGI::App::Router->new;
    my @tracker;

    my $mw1 = sub {
        my ($app) = @_;
        async sub {
            my ($scope, $receive, $send) = @_;
            push @tracker, 'mw1:before';
            await $app->($scope, $receive, $send);
            push @tracker, 'mw1:after';
        };
    };

    my $mw2 = sub {
        my ($app) = @_;
        async sub {
            my ($scope, $receive, $send) = @_;
            push @tracker, 'mw2:before';
            await $app->($scope, $receive, $send);
            push @tracker, 'mw2:after';
        };
    };

    my $mw3 = sub {
        my ($app) = @_;
        async sub {
            my ($scope, $receive, $send) = @_;
            push @tracker, 'mw3:before';
            await $app->($scope, $receive, $send);
            push @tracker, 'mw3:after';
        };
    };

    $router->get('/' => [$mw1, $mw2, $mw3] => make_app('home', \@tracker));

    my $app = $router->to_app;
    my $events = request($app, path => '/')->get;

    is \@tracker, [
        'mw1:before', 'mw2:before', 'mw3:before',
        'app:home',
        'mw3:after', 'mw2:after', 'mw1:after',
    ], 'onion model: request order, reverse response order';
};

subtest 'middleware can short-circuit' => sub {
    my $router = PAGI::App::Router->new;
    my @tracker;

    # Factory whose inner sub responds without ever calling $app.
    my $auth = sub {
        my ($app) = @_;
        async sub {
            my ($scope, $receive, $send) = @_;
            push @tracker, 'auth:check';
            # Do not call $app — short-circuit.
            await $send->({
                type    => 'http.response.start',
                status  => 401,
                headers => [['content-type', 'text/plain']],
            });
            await $send->({
                type => 'http.response.body',
                body => 'Unauthorized',
                more => 0,
            });
        };
    };

    $router->get('/' => [$auth] => make_app('home', \@tracker));

    my $app = $router->to_app;
    my $events = request($app, path => '/')->get;

    is \@tracker, ['auth:check'], 'app was not called';
    is $events->[0]{status}, 401, 'got 401 from middleware';
};

subtest 'middleware can modify scope' => sub {
    my $router = PAGI::App::Router->new;
    my $captured_scope;

    # Factory that stamps custom_data onto the scope before calling $app.
    my $modify_scope = sub {
        my ($app) = @_;
        async sub {
            my ($scope, $receive, $send) = @_;
            $scope->{custom_data} = 'from_middleware';
            await $app->($scope, $receive, $send);
        };
    };

    my $app_handler = async sub {
        my ($scope, $receive, $send) = @_;
        $captured_scope = $scope;
        await $send->({
            type    => 'http.response.start',
            status  => 200,
            headers => [],
        });
        await $send->({ type => 'http.response.body', body => 'ok', more => 0 });
    };

    $router->get('/' => [$modify_scope] => $app_handler);

    my $app = $router->to_app;
    request($app, path => '/')->get;

    is $captured_scope->{custom_data}, 'from_middleware', 'scope was modified';
};

subtest 'PAGI::Middleware instance' => sub {
    my $router = PAGI::App::Router->new;
    my @tracker;

    # Object middleware: wrap() is called once at build time and returns the handler.
    {
        package TestMiddleware;
        use Future::AsyncAwait;

        sub new {
            my ($class, %args) = @_;
            return bless { tracker => $args{tracker}, name => $args{name} }, $class;
        }

        sub wrap {
            my ($self, $app) = @_;
            return async sub {
                my ($scope, $receive, $send) = @_;
                push @{$self->{tracker}}, "$self->{name}:before";
                await $app->($scope, $receive, $send);
                push @{$self->{tracker}}, "$self->{name}:after";
            };
        }
    }

    my $mw = TestMiddleware->new(tracker => \@tracker, name => 'test_mw');

    $router->get('/' => [$mw] => make_app('home', \@tracker));

    my $app = $router->to_app;
    my $events = request($app, path => '/')->get;

    is \@tracker, ['test_mw:before', 'app:home', 'test_mw:after'], 'middleware instance worked';
    is $events->[0]{status}, 200, 'got 200 response';
};

subtest 'mount with middleware' => sub {
    my $router = PAGI::App::Router->new;
    my @tracker;

    my $mw = sub {
        my ($app) = @_;
        async sub {
            my ($scope, $receive, $send) = @_;
            push @tracker, 'mount_mw:before';
            await $app->($scope, $receive, $send);
            push @tracker, 'mount_mw:after';
        };
    };

    my $sub_router = PAGI::App::Router->new;
    $sub_router->get('/users' => make_app('users', \@tracker));

    $router->mount('/api' => [$mw] => $sub_router->to_app);

    my $app = $router->to_app;
    my $events = request($app, path => '/api/users')->get;

    is \@tracker, ['mount_mw:before', 'app:users', 'mount_mw:after'], 'mount middleware ran';
    is $events->[0]{status}, 200, 'got 200 response';
};

subtest 'stacked middleware - mount + route' => sub {
    my $router = PAGI::App::Router->new;
    my @tracker;

    my $outer_mw = sub {
        my ($app) = @_;
        async sub {
            my ($scope, $receive, $send) = @_;
            push @tracker, 'outer:before';
            await $app->($scope, $receive, $send);
            push @tracker, 'outer:after';
        };
    };

    my $inner_mw = sub {
        my ($app) = @_;
        async sub {
            my ($scope, $receive, $send) = @_;
            push @tracker, 'inner:before';
            await $app->($scope, $receive, $send);
            push @tracker, 'inner:after';
        };
    };

    my $sub_router = PAGI::App::Router->new;
    $sub_router->get('/data' => [$inner_mw] => make_app('data', \@tracker));

    $router->mount('/api' => [$outer_mw] => $sub_router->to_app);

    my $app = $router->to_app;
    my $events = request($app, path => '/api/data')->get;

    is \@tracker, [
        'outer:before', 'inner:before',
        'app:data',
        'inner:after', 'outer:after',
    ], 'middleware stacked correctly';
};

subtest 'websocket route with middleware' => sub {
    my $router = PAGI::App::Router->new;
    my @tracker;

    my $mw = sub {
        my ($app) = @_;
        async sub {
            my ($scope, $receive, $send) = @_;
            push @tracker, 'ws_mw:before';
            await $app->($scope, $receive, $send);
            push @tracker, 'ws_mw:after';
        };
    };

    my $ws_handler = async sub {
        my ($scope, $receive, $send) = @_;
        push @tracker, 'ws:handler';
        # Just return for test
    };

    $router->websocket('/ws' => [$mw] => $ws_handler);

    my $app = $router->to_app;
    request($app, type => 'websocket', path => '/ws')->get;

    is \@tracker, ['ws_mw:before', 'ws:handler', 'ws_mw:after'], 'websocket middleware ran';
};

subtest 'sse route with middleware' => sub {
    my $router = PAGI::App::Router->new;
    my @tracker;

    my $mw = sub {
        my ($app) = @_;
        async sub {
            my ($scope, $receive, $send) = @_;
            push @tracker, 'sse_mw:before';
            await $app->($scope, $receive, $send);
            push @tracker, 'sse_mw:after';
        };
    };

    my $sse_handler = async sub {
        my ($scope, $receive, $send) = @_;
        push @tracker, 'sse:handler';
    };

    $router->sse('/events' => [$mw] => $sse_handler);

    my $app = $router->to_app;
    request($app, type => 'sse', path => '/events')->get;

    is \@tracker, ['sse_mw:before', 'sse:handler', 'sse_mw:after'], 'sse middleware ran';
};

subtest 'invalid middleware - dies at registration' => sub {
    my $router = PAGI::App::Router->new;

    like dies {
        $router->get('/' => ['not_a_middleware'] => sub {});
    }, qr/Invalid middleware/, 'string middleware rejected';

    like dies {
        $router->get('/' => [{ hash => 'ref' }] => sub {});
    }, qr/Invalid middleware/, 'hashref middleware rejected';

    like dies {
        # Object without wrap method
        my $obj = bless {}, 'SomeClass';
        $router->get('/' => [$obj] => sub {});
    }, qr/Invalid middleware/, 'object without wrap() rejected';
};

subtest 'empty middleware array' => sub {
    my $router = PAGI::App::Router->new;
    my @tracker;

    $router->get('/' => [] => make_app('home', \@tracker));

    my $app = $router->to_app;
    my $events = request($app, path => '/')->get;

    is \@tracker, ['app:home'], 'empty middleware array works';
    is $events->[0]{status}, 200, 'got 200 response';
};

subtest 'mixed middleware types' => sub {
    my $router = PAGI::App::Router->new;
    my @tracker;

    {
        package MixedTestMiddleware;
        use Future::AsyncAwait;

        sub new { bless { tracker => $_[1] }, $_[0] }

        sub wrap {
            my ($self, $app) = @_;
            return async sub {
                my ($scope, $receive, $send) = @_;
                push @{$self->{tracker}}, 'instance:before';
                await $app->($scope, $receive, $send);
                push @{$self->{tracker}}, 'instance:after';
            };
        }
    }

    my $instance_mw = MixedTestMiddleware->new(\@tracker);

    my $coderef_mw = sub {
        my ($app) = @_;
        async sub {
            my ($scope, $receive, $send) = @_;
            push @tracker, 'coderef:before';
            await $app->($scope, $receive, $send);
            push @tracker, 'coderef:after';
        };
    };

    $router->get('/' => [$instance_mw, $coderef_mw] => make_app('home', \@tracker));

    my $app = $router->to_app;
    my $events = request($app, path => '/')->get;

    is \@tracker, [
        'instance:before', 'coderef:before',
        'app:home',
        'coderef:after', 'instance:after',
    ], 'mixed middleware types work together';
};

subtest 'coderef middleware can wrap the receive channel' => sub {
    my $router = PAGI::App::Router->new;

    # Middleware injects a synthetic event ahead of the real receive.
    my $inject = sub {
        my ($app) = @_;
        async sub {
            my ($scope, $receive, $send) = @_;
            my $done = 0;
            my $wrapped_receive = async sub {
                return { type => 'tick' } unless $done++;
                return await $receive->();
            };
            await $app->($scope, $wrapped_receive, $send);
        };
    };

    # App reports the first event type it sees on the channel.
    my $app_handler = async sub {
        my ($scope, $receive, $send) = @_;
        my $event = await $receive->();
        await $send->({ type => 'http.response.start', status => 200, headers => [] });
        await $send->({ type => 'http.response.body', body => $event->{type}, more => 0 });
    };

    $router->get('/' => [$inject] => $app_handler);
    my $events = request($router->to_app, path => '/')->get;

    is $events->[1]{body}, 'tick', 'handler saw the injected event from the wrapped receive';
};

subtest 'coderef middleware can wrap the send channel' => sub {
    my $router = PAGI::App::Router->new;

    # Middleware stamps a header onto the response start event.
    my $stamp = sub {
        my ($app) = @_;
        async sub {
            my ($scope, $receive, $send) = @_;
            my $wrapped_send = async sub {
                my ($event) = @_;
                $event = { %$event, headers => [ @{ $event->{headers} // [] }, ['x-powered-by', 'PAGI'] ] }
                    if $event->{type} eq 'http.response.start';
                await $send->($event);
            };
            await $app->($scope, $receive, $wrapped_send);
        };
    };

    my $app_handler = async sub {
        my ($scope, $receive, $send) = @_;
        await $send->({ type => 'http.response.start', status => 200, headers => [] });
        await $send->({ type => 'http.response.body', body => 'ok', more => 0 });
    };

    $router->get('/' => [$stamp] => $app_handler);
    my $events = request($router->to_app, path => '/')->get;

    my %headers = map { @$_ } @{ $events->[0]{headers} };
    is $headers{'x-powered-by'}, 'PAGI', 'response carries the header added by the wrapped send';
};

subtest 'wrap is called once at build time, not per request' => sub {
    my $router = PAGI::App::Router->new;

    # $counter lives in factory scope; if wrap() ran per request it would reset each time.
    my $counter_mw = sub {
        my ($app) = @_;
        my $counter = 0;
        async sub {
            my ($scope, $receive, $send) = @_;
            my $n = ++$counter;
            my $wrapped_send = async sub {
                my ($event) = @_;
                $event = { %$event, headers => [ @{ $event->{headers} // [] }, ['x-call-count', "$n"] ] }
                    if $event->{type} eq 'http.response.start';
                await $send->($event);
            };
            await $app->($scope, $receive, $wrapped_send);
        };
    };

    $router->get('/' => [$counter_mw] => make_app('home'));
    my $app = $router->to_app;

    my $events1 = request($app, path => '/')->get;
    my $events2 = request($app, path => '/')->get;

    my %h1 = map { @$_ } @{ $events1->[0]{headers} };
    my %h2 = map { @$_ } @{ $events2->[0]{headers} };

    is $h1{'x-call-count'}, '1', 'first request: counter is 1';
    is $h2{'x-call-count'}, '2', 'second request: counter is 2 (wrap called once at build time)';
};

done_testing;
