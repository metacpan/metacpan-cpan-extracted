#!/usr/bin/env perl

# =============================================================================
# Test: Middleware Builder class name resolution
#
# Tests the ^ prefix for fully-qualified class names and ensures nested
# namespace middleware (like Auth::Basic) works correctly.
# =============================================================================

use strict;
use warnings;
use Test2::V0;

use FindBin;
use lib 'lib', "$FindBin::Bin/lib";
use Future::AsyncAwait;
use PAGI::Middleware::Builder;

# =============================================================================
# Test _resolve_middleware directly
# =============================================================================

subtest 'middleware class resolution' => sub {
    my $builder = PAGI::Middleware::Builder->new;

    # Simple names get prefixed
    is $builder->_resolve_middleware('GZIP'),
        'PAGI::Middleware::GZIP',
        'simple name gets PAGI::Middleware:: prefix';

    is $builder->_resolve_middleware('ContentLength'),
        'PAGI::Middleware::ContentLength',
        'ContentLength gets prefix';

    # Nested namespaces also get prefixed (the bug fix)
    is $builder->_resolve_middleware('Auth::Basic'),
        'PAGI::Middleware::Auth::Basic',
        'Auth::Basic gets PAGI::Middleware:: prefix';

    is $builder->_resolve_middleware('Auth::Bearer'),
        'PAGI::Middleware::Auth::Bearer',
        'Auth::Bearer gets PAGI::Middleware:: prefix';

    is $builder->_resolve_middleware('WebSocket::RateLimit'),
        'PAGI::Middleware::WebSocket::RateLimit',
        'WebSocket::RateLimit gets PAGI::Middleware:: prefix';

    is $builder->_resolve_middleware('SSE::Retry'),
        'PAGI::Middleware::SSE::Retry',
        'SSE::Retry gets PAGI::Middleware:: prefix';

    # Caret prefix prevents automatic prefixing
    is $builder->_resolve_middleware('^My::Custom::Middleware'),
        'My::Custom::Middleware',
        '^My::Custom::Middleware uses exact class name';

    is $builder->_resolve_middleware('^TopLevel'),
        'TopLevel',
        '^TopLevel uses exact class name (top-level)';

    is $builder->_resolve_middleware('^Some::Deep::Nested::Class'),
        'Some::Deep::Nested::Class',
        'deeply nested class with ^ works';
};

# =============================================================================
# Test with actual middleware loading
# =============================================================================

subtest 'loading real nested middleware' => sub {
    my $builder = PAGI::Middleware::Builder->new;

    # These should resolve and load correctly
    my $class1 = $builder->_resolve_middleware('Auth::Basic');
    is $class1, 'PAGI::Middleware::Auth::Basic', 'Auth::Basic resolves correctly';
    ok $class1->can('wrap'), 'Auth::Basic class loaded and has wrap method';

    my $class2 = $builder->_resolve_middleware('WebSocket::RateLimit');
    is $class2, 'PAGI::Middleware::WebSocket::RateLimit', 'WebSocket::RateLimit resolves correctly';
    ok $class2->can('wrap'), 'WebSocket::RateLimit class loaded and has wrap method';
};

# =============================================================================
# Test enable() with a configured middleware instance
# =============================================================================

subtest 'enable accepts a configured middleware instance' => sub {
    require PAGI::Middleware::Head;
    require TestApps::Component;

    my $app = builder {
        enable(PAGI::Middleware::Head->new);
        TestApps::Component->new(body => 'with-head');
    };

    my @sent;
    my $send = sub { my ($msg) = @_; push @sent, $msg; Future->done };

    # HEAD request: Head middleware converts to GET internally but suppresses body
    $app->({ type => 'http', method => 'HEAD', path => '/' },
        sub { Future->done }, $send)->get;
    is $sent[0]{status}, 200, 'instance middleware ran (response start passed through)';
    is $sent[1]{body}, '', 'Head middleware stripped body for HEAD request';
};

subtest 'enable_if accepts a configured middleware instance' => sub {
    require PAGI::Middleware::Head;
    require TestApps::Component;

    # Condition FALSE: inner app runs unmodified, HEAD body is NOT stripped
    my $app_skip = builder {
        enable_if { 0 } (PAGI::Middleware::Head->new);
        TestApps::Component->new(body => 'skip-head');
    };

    my @sent;
    my $send = sub { my ($msg) = @_; push @sent, $msg; Future->done };

    $app_skip->({ type => 'http', method => 'HEAD', path => '/' },
        sub { Future->done }, $send)->get;
    is $sent[1]{body}, 'skip-head', 'condition false: instance middleware bypassed';

    # Condition TRUE: Head middleware runs and strips body
    my $app_run = builder {
        enable_if { 1 } (PAGI::Middleware::Head->new);
        TestApps::Component->new(body => 'run-head');
    };

    @sent = ();
    $app_run->({ type => 'http', method => 'HEAD', path => '/' },
        sub { Future->done }, $send)->get;
    is $sent[0]{status}, 200, 'condition true: instance middleware ran';
    is $sent[1]{body}, '', 'condition true: Head middleware stripped body';
};

subtest 'enable croaks on instance plus config' => sub {
    require PAGI::Middleware::Head;
    my $builder = PAGI::Middleware::Builder->new;
    like dies { $builder->add_middleware(PAGI::Middleware::Head->new, foo => 1) },
        qr/takes no config/,
        'config with instance belongs at construction time';

    like dies { PAGI::Middleware::Builder->new->add_middleware(bless {}, 'TestApps::NotMiddleware') },
        qr/no wrap method/,
        'blessed object without wrap croaks';

    like dies { PAGI::Middleware::Builder->new->add_middleware_if(sub { 1 }, PAGI::Middleware::Head->new, foo => 1) },
        qr/takes no config/,
        'enable_if instance plus config croaks';
};

subtest 'builder coerces mounts and the final app' => sub {
    require TestApps::Component;

    my $app = builder {
        mount '/c' => TestApps::Component->new(body => 'mounted');
        TestApps::Component->new(body => 'fallback');
    };

    my @sent;
    my $send = sub { my ($msg) = @_; push @sent, $msg; Future->done };
    $app->({ type => 'http', method => 'GET', path => '/c/x' },
        sub { Future->done }, $send)->get;
    is $sent[1]{body}, 'mounted', 'mounted component coerced to app';

    @sent = ();
    $app->({ type => 'http', method => 'GET', path => '/other' },
        sub { Future->done }, $send)->get;
    is $sent[1]{body}, 'fallback', 'final block value coerced to app';
};

done_testing;
