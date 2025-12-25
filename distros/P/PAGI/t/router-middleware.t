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

    my $mw = async sub {
        my ($scope, $receive, $send, $next) = @_;
        push @tracker, 'mw:before';
        await $next->();
        push @tracker, 'mw:after';
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

    my $mw1 = async sub {
        my ($scope, $receive, $send, $next) = @_;
        push @tracker, 'mw1:before';
        await $next->();
        push @tracker, 'mw1:after';
    };

    my $mw2 = async sub {
        my ($scope, $receive, $send, $next) = @_;
        push @tracker, 'mw2:before';
        await $next->();
        push @tracker, 'mw2:after';
    };

    my $mw3 = async sub {
        my ($scope, $receive, $send, $next) = @_;
        push @tracker, 'mw3:before';
        await $next->();
        push @tracker, 'mw3:after';
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

    my $auth = async sub {
        my ($scope, $receive, $send, $next) = @_;
        push @tracker, 'auth:check';
        # Don't call $next - short circuit
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

    $router->get('/' => [$auth] => make_app('home', \@tracker));

    my $app = $router->to_app;
    my $events = request($app, path => '/')->get;

    is \@tracker, ['auth:check'], 'app was not called';
    is $events->[0]{status}, 401, 'got 401 from middleware';
};

subtest 'middleware can modify scope' => sub {
    my $router = PAGI::App::Router->new;
    my $captured_scope;

    my $add_user = async sub {
        my ($scope, $receive, $send, $next) = @_;
        # Create new scope with user info
        my $new_scope = { %$scope, user => { id => 42, name => 'Test' } };
        # Need to call app with new scope - but $next captures original
        # This requires a different approach...
        await $next->();
    };

    # For scope modification, middleware needs to call the next handler directly
    # Let's test a simpler case - modifying via scope reference
    my $modify_scope = async sub {
        my ($scope, $receive, $send, $next) = @_;
        $scope->{custom_data} = 'from_middleware';
        await $next->();
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

    # Create a simple middleware class
    {
        package TestMiddleware;
        use Future::AsyncAwait;

        sub new {
            my ($class, %args) = @_;
            return bless { tracker => $args{tracker}, name => $args{name} }, $class;
        }

        async sub call {
            my ($self, $scope, $receive, $send, $app) = @_;
            push @{$self->{tracker}}, "$self->{name}:before";
            my $wrapped = $self->wrap($app);
            await $wrapped->($scope, $receive, $send);
            push @{$self->{tracker}}, "$self->{name}:after";
        }

        sub wrap {
            my ($self, $app) = @_;
            return async sub {
                my ($scope, $receive, $send) = @_;
                await $app->($scope, $receive, $send);
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

    my $mw = async sub {
        my ($scope, $receive, $send, $next) = @_;
        push @tracker, 'mount_mw:before';
        await $next->();
        push @tracker, 'mount_mw:after';
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

    my $outer_mw = async sub {
        my ($scope, $receive, $send, $next) = @_;
        push @tracker, 'outer:before';
        await $next->();
        push @tracker, 'outer:after';
    };

    my $inner_mw = async sub {
        my ($scope, $receive, $send, $next) = @_;
        push @tracker, 'inner:before';
        await $next->();
        push @tracker, 'inner:after';
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

    my $mw = async sub {
        my ($scope, $receive, $send, $next) = @_;
        push @tracker, 'ws_mw:before';
        await $next->();
        push @tracker, 'ws_mw:after';
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

    my $mw = async sub {
        my ($scope, $receive, $send, $next) = @_;
        push @tracker, 'sse_mw:before';
        await $next->();
        push @tracker, 'sse_mw:after';
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
        # Object without call method
        my $obj = bless {}, 'SomeClass';
        $router->get('/' => [$obj] => sub {});
    }, qr/Invalid middleware/, 'object without call() rejected';
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

        async sub call {
            my ($self, $scope, $receive, $send, $app) = @_;
            push @{$self->{tracker}}, 'instance:before';
            await $app->($scope, $receive, $send);
            push @{$self->{tracker}}, 'instance:after';
        }
    }

    my $instance_mw = MixedTestMiddleware->new(\@tracker);

    my $coderef_mw = async sub {
        my ($scope, $receive, $send, $next) = @_;
        push @tracker, 'coderef:before';
        await $next->();
        push @tracker, 'coderef:after';
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

done_testing;
