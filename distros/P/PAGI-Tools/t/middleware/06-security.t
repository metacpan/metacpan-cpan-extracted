#!/usr/bin/env perl

use strict;
use warnings;
use Test2::V0;
use Future::AsyncAwait;
use IO::Async::Loop;

use lib 'lib';

use PAGI::Middleware::CORS;
use PAGI::Middleware::SecurityHeaders;
use PAGI::Middleware::TrustedHosts;
use PAGI::Middleware::CSRF;

my $loop = IO::Async::Loop->new;

sub run_async {
    my ($code) = @_;
    my $future = $code->();
    $loop->await($future);
}

# =============================================================================
# Test: CORS middleware handles preflight requests
# =============================================================================

subtest 'CORS handles preflight OPTIONS request' => sub {
    my $mw = PAGI::Middleware::CORS->new(
        origins => ['https://example.com'],
        methods => ['GET', 'POST', 'PUT'],
        headers => ['Content-Type', 'Authorization'],
    );

    my $app_called = 0;
    my $app = async sub  {
        my ($scope, $receive, $send) = @_;
        $app_called = 1;
        await $send->({
            type    => 'http.response.start',
            status  => 200,
            headers => [],
        });
        await $send->({
            type => 'http.response.body',
            body => 'OK',
            more => 0,
        });
    };

    my $wrapped = $mw->wrap($app);

    my @sent;
    run_async(async sub {
        await $wrapped->(
            {
                type    => 'http',
                path    => '/api/resource',
                method  => 'OPTIONS',
                headers => [
                    ['origin', 'https://example.com'],
                    ['access-control-request-method', 'POST'],
                ],
            },
            async sub { { type => 'http.disconnect' } },
            async sub  {
        my ($event) = @_; push @sent, $event },
        );
    });

    ok !$app_called, 'app not called for preflight';
    is $sent[0]{status}, 204, 'preflight returns 204';

    my %headers = map { lc($_->[0]) => $_->[1] } @{$sent[0]{headers}};
    is $headers{'access-control-allow-origin'}, 'https://example.com', 'Allow-Origin header present';
    like $headers{'access-control-allow-methods'}, qr/POST/, 'Allow-Methods contains POST';
    like $headers{'access-control-allow-headers'}, qr/Content-Type/, 'Allow-Headers present';
};

subtest 'CORS adds headers to actual requests' => sub {
    my $mw = PAGI::Middleware::CORS->new(
        origins     => ['https://example.com'],
        credentials => 1,
    );

    my $app = async sub  {
        my ($scope, $receive, $send) = @_;
        await $send->({
            type    => 'http.response.start',
            status  => 200,
            headers => [['content-type', 'application/json']],
        });
        await $send->({
            type => 'http.response.body',
            body => '{"data":"test"}',
            more => 0,
        });
    };

    my $wrapped = $mw->wrap($app);

    my @sent;
    run_async(async sub {
        await $wrapped->(
            {
                type    => 'http',
                path    => '/api/data',
                method  => 'GET',
                headers => [['origin', 'https://example.com']],
            },
            async sub { { type => 'http.disconnect' } },
            async sub  {
        my ($event) = @_; push @sent, $event },
        );
    });

    my %headers = map { lc($_->[0]) => $_->[1] } @{$sent[0]{headers}};
    is $headers{'access-control-allow-origin'}, 'https://example.com', 'Origin header on response';
    is $headers{'access-control-allow-credentials'}, 'true', 'Credentials header present';
};

subtest 'CORS rejects unknown origins' => sub {
    my $mw = PAGI::Middleware::CORS->new(
        origins => ['https://allowed.com'],
    );

    my $app = async sub  {
        my ($scope, $receive, $send) = @_;
        await $send->({
            type    => 'http.response.start',
            status  => 200,
            headers => [],
        });
        await $send->({
            type => 'http.response.body',
            body => 'OK',
            more => 0,
        });
    };

    my $wrapped = $mw->wrap($app);

    my @sent;
    run_async(async sub {
        await $wrapped->(
            {
                type    => 'http',
                path    => '/api/data',
                method  => 'GET',
                headers => [['origin', 'https://evil.com']],
            },
            async sub { { type => 'http.disconnect' } },
            async sub  {
        my ($event) = @_; push @sent, $event },
        );
    });

    # Response should not have CORS headers for unknown origin
    my @cors_headers = grep { $_->[0] =~ /^access-control/i } @{$sent[0]{headers}};
    is scalar(@cors_headers), 0, 'no CORS headers for unknown origin';
};

# =============================================================================
# Test: SecurityHeaders middleware adds security headers
# =============================================================================

subtest 'SecurityHeaders adds X-Content-Type-Options' => sub {
    my $mw = PAGI::Middleware::SecurityHeaders->new;

    my $app = async sub  {
        my ($scope, $receive, $send) = @_;
        await $send->({
            type    => 'http.response.start',
            status  => 200,
            headers => [['content-type', 'text/html']],
        });
        await $send->({
            type => 'http.response.body',
            body => '<html>Test</html>',
            more => 0,
        });
    };

    my $wrapped = $mw->wrap($app);

    my @sent;
    run_async(async sub {
        await $wrapped->(
            { type => 'http', path => '/', method => 'GET', headers => [] },
            async sub { { type => 'http.disconnect' } },
            async sub  {
        my ($event) = @_; push @sent, $event },
        );
    });

    my %headers = map { lc($_->[0]) => $_->[1] } @{$sent[0]{headers}};
    is $headers{'x-content-type-options'}, 'nosniff', 'X-Content-Type-Options is nosniff';
};

subtest 'SecurityHeaders adds X-Frame-Options' => sub {
    my $mw = PAGI::Middleware::SecurityHeaders->new(
        x_frame_options => 'DENY',
    );

    my $app = async sub  {
        my ($scope, $receive, $send) = @_;
        await $send->({
            type    => 'http.response.start',
            status  => 200,
            headers => [],
        });
        await $send->({
            type => 'http.response.body',
            body => 'OK',
            more => 0,
        });
    };

    my $wrapped = $mw->wrap($app);

    my @sent;
    run_async(async sub {
        await $wrapped->(
            { type => 'http', path => '/', method => 'GET', headers => [] },
            async sub { { type => 'http.disconnect' } },
            async sub  {
        my ($event) = @_; push @sent, $event },
        );
    });

    my %headers = map { lc($_->[0]) => $_->[1] } @{$sent[0]{headers}};
    is $headers{'x-frame-options'}, 'DENY', 'X-Frame-Options is DENY';
};

subtest 'SecurityHeaders adds all default headers' => sub {
    my $mw = PAGI::Middleware::SecurityHeaders->new;

    my $app = async sub  {
        my ($scope, $receive, $send) = @_;
        await $send->({
            type    => 'http.response.start',
            status  => 200,
            headers => [],
        });
        await $send->({
            type => 'http.response.body',
            body => 'OK',
            more => 0,
        });
    };

    my $wrapped = $mw->wrap($app);

    my @sent;
    run_async(async sub {
        await $wrapped->(
            { type => 'http', path => '/', method => 'GET', headers => [] },
            async sub { { type => 'http.disconnect' } },
            async sub  {
        my ($event) = @_; push @sent, $event },
        );
    });

    my %headers = map { lc($_->[0]) => $_->[1] } @{$sent[0]{headers}};
    ok exists $headers{'x-frame-options'}, 'X-Frame-Options present';
    ok exists $headers{'x-content-type-options'}, 'X-Content-Type-Options present';
    ok exists $headers{'x-xss-protection'}, 'X-XSS-Protection present';
    ok exists $headers{'referrer-policy'}, 'Referrer-Policy present';
};

# =============================================================================
# Test: TrustedHosts middleware validates Host header
# =============================================================================

subtest 'TrustedHosts allows valid hosts' => sub {
    my $mw = PAGI::Middleware::TrustedHosts->new(
        hosts => ['example.com', 'www.example.com'],
    );

    my $app_called = 0;
    my $app = async sub  {
        my ($scope, $receive, $send) = @_;
        $app_called = 1;
        await $send->({
            type    => 'http.response.start',
            status  => 200,
            headers => [],
        });
        await $send->({
            type => 'http.response.body',
            body => 'OK',
            more => 0,
        });
    };

    my $wrapped = $mw->wrap($app);

    my @sent;
    run_async(async sub {
        await $wrapped->(
            {
                type    => 'http',
                path    => '/',
                method  => 'GET',
                headers => [['host', 'example.com']],
            },
            async sub { { type => 'http.disconnect' } },
            async sub  {
        my ($event) = @_; push @sent, $event },
        );
    });

    ok $app_called, 'app called for valid host';
    is $sent[0]{status}, 200, 'status is 200';
};

subtest 'TrustedHosts rejects invalid hosts' => sub {
    my $mw = PAGI::Middleware::TrustedHosts->new(
        hosts => ['example.com'],
    );

    my $app_called = 0;
    my $app = async sub  {
        my ($scope, $receive, $send) = @_;
        $app_called = 1;
    };

    my $wrapped = $mw->wrap($app);

    my @sent;
    run_async(async sub {
        await $wrapped->(
            {
                type    => 'http',
                path    => '/',
                method  => 'GET',
                headers => [['host', 'evil.com']],
            },
            async sub { { type => 'http.disconnect' } },
            async sub  {
        my ($event) = @_; push @sent, $event },
        );
    });

    ok !$app_called, 'app not called for invalid host';
    is $sent[0]{status}, 400, 'status is 400 Bad Request';
};

subtest 'TrustedHosts supports wildcard patterns' => sub {
    my $mw = PAGI::Middleware::TrustedHosts->new(
        hosts => ['*.example.com'],
    );

    my $app_called = 0;
    my $app = async sub  {
        my ($scope, $receive, $send) = @_;
        $app_called = 1;
        await $send->({
            type    => 'http.response.start',
            status  => 200,
            headers => [],
        });
        await $send->({
            type => 'http.response.body',
            body => 'OK',
            more => 0,
        });
    };

    my $wrapped = $mw->wrap($app);

    run_async(async sub {
        await $wrapped->(
            {
                type    => 'http',
                path    => '/',
                method  => 'GET',
                headers => [['host', 'api.example.com']],
            },
            async sub { { type => 'http.disconnect' } },
            async sub  {
        my ($event) = @_; },
        );
    });

    ok $app_called, 'wildcard pattern matches subdomain';
};

# =============================================================================
# Test: CSRF middleware validates tokens on POST requests
# =============================================================================

subtest 'CSRF rejects POST without token' => sub {
    my $mw = PAGI::Middleware::CSRF->new(secret => 'test-secret');

    my $app_called = 0;
    my $app = async sub  {
        my ($scope, $receive, $send) = @_;
        $app_called = 1;
    };

    my $wrapped = $mw->wrap($app);

    my @sent;
    run_async(async sub {
        await $wrapped->(
            {
                type    => 'http',
                path    => '/submit',
                method  => 'POST',
                headers => [],
            },
            async sub { { type => 'http.disconnect' } },
            async sub  {
        my ($event) = @_; push @sent, $event },
        );
    });

    ok !$app_called, 'app not called without token';
    is $sent[0]{status}, 403, 'status is 403 Forbidden';
};

subtest 'CSRF allows POST with valid token' => sub {
    my $mw = PAGI::Middleware::CSRF->new(secret => 'test-secret');

    # Generate a token first with a GET request
    my $token;
    my $app = async sub  {
        my ($scope, $receive, $send) = @_;
        $token = $scope->{csrf_token};
        await $send->({
            type    => 'http.response.start',
            status  => 200,
            headers => [],
        });
        await $send->({
            type => 'http.response.body',
            body => 'OK',
            more => 0,
        });
    };

    my $wrapped = $mw->wrap($app);

    # GET request to get token
    my @sent1;
    run_async(async sub {
        await $wrapped->(
            {
                type    => 'http',
                path    => '/',
                method  => 'GET',
                headers => [],
            },
            async sub { { type => 'http.disconnect' } },
            async sub  {
        my ($event) = @_; push @sent1, $event },
        );
    });

    ok $token, 'token generated on GET';

    # Extract Set-Cookie token
    my $cookie_token;
    for my $h (@{$sent1[0]{headers}}) {
        if (lc($h->[0]) eq 'set-cookie' && $h->[1] =~ /csrf_token=([^;]+)/) {
            $cookie_token = $1;
            last;
        }
    }
    ok $cookie_token, 'token set in cookie';

    # POST request with token
    my $post_called = 0;
    my $post_app = async sub  {
        my ($scope, $receive, $send) = @_;
        $post_called = 1;
        await $send->({
            type    => 'http.response.start',
            status  => 200,
            headers => [],
        });
        await $send->({
            type => 'http.response.body',
            body => 'Created',
            more => 0,
        });
    };

    my $wrapped2 = $mw->wrap($post_app);

    my @sent2;
    run_async(async sub {
        await $wrapped2->(
            {
                type    => 'http',
                path    => '/submit',
                method  => 'POST',
                headers => [
                    ['cookie', "csrf_token=$cookie_token"],
                    ['x-csrf-token', $cookie_token],
                ],
            },
            async sub { { type => 'http.disconnect' } },
            async sub  {
        my ($event) = @_; push @sent2, $event },
        );
    });

    ok $post_called, 'app called with valid token';
    is $sent2[0]{status}, 200, 'POST succeeds with valid token';
};

subtest 'CSRF allows GET without token' => sub {
    my $mw = PAGI::Middleware::CSRF->new(secret => 'test-secret');

    my $app_called = 0;
    my $app = async sub  {
        my ($scope, $receive, $send) = @_;
        $app_called = 1;
        await $send->({
            type    => 'http.response.start',
            status  => 200,
            headers => [],
        });
        await $send->({
            type => 'http.response.body',
            body => 'OK',
            more => 0,
        });
    };

    my $wrapped = $mw->wrap($app);

    my @sent;
    run_async(async sub {
        await $wrapped->(
            {
                type    => 'http',
                path    => '/page',
                method  => 'GET',
                headers => [],
            },
            async sub { { type => 'http.disconnect' } },
            async sub  {
        my ($event) = @_; push @sent, $event },
        );
    });

    ok $app_called, 'app called for GET without token';
    is $sent[0]{status}, 200, 'GET succeeds without token';
};

# =============================================================================
# Test: CSRF 'enforce' config - 'header' (default) vs 'app' (issue-only)
# =============================================================================

subtest 'CSRF rejects invalid enforce value' => sub {
    like(
        dies { PAGI::Middleware::CSRF->new(secret => 'test-secret', enforce => 'bogus') },
        qr/enforce/,
        'constructor dies on an unrecognized enforce value',
    );
};

subtest "CSRF enforce => 'header' behaves exactly like the default" => sub {
    my $mw = PAGI::Middleware::CSRF->new(secret => 'test-secret', enforce => 'header');

    my $app_called = 0;
    my $app = async sub  {
        my ($scope, $receive, $send) = @_;
        $app_called = 1;
    };

    my $wrapped = $mw->wrap($app);

    my @sent;
    run_async(async sub {
        await $wrapped->(
            {
                type    => 'http',
                path    => '/submit',
                method  => 'POST',
                headers => [],
            },
            async sub { { type => 'http.disconnect' } },
            async sub  {
        my ($event) = @_; push @sent, $event },
        );
    });

    ok !$app_called, 'app not called without token';
    is $sent[0]{status}, 403, 'status is 403 Forbidden, same as default enforcement';
};

subtest "CSRF enforce => 'app' passes an unsafe request through with no token" => sub {
    my $mw = PAGI::Middleware::CSRF->new(secret => 'test-secret', enforce => 'app');

    my $seen_token;
    my $app_called = 0;
    my $app = async sub  {
        my ($scope, $receive, $send) = @_;
        $app_called   = 1;
        $seen_token   = $scope->{csrf_token};
        await $send->({ type => 'http.response.start', status => 200, headers => [] });
        await $send->({ type => 'http.response.body', body => 'OK', more => 0 });
    };

    my $wrapped = $mw->wrap($app);

    my @sent;
    run_async(async sub {
        await $wrapped->(
            {
                type    => 'http',
                path    => '/submit',
                method  => 'POST',
                headers => [],
            },
            async sub { { type => 'http.disconnect' } },
            async sub  {
        my ($event) = @_; push @sent, $event },
        );
    });

    ok $app_called, "app mode: unsafe POST with no submitted token still reaches the app";
    is $sent[0]{status}, 200, 'no auto-403 in app mode';
    ok $seen_token, 'a freshly minted token is stashed into scope';

    my ($set_cookie) = grep { lc($_->[0]) eq 'set-cookie' } @{$sent[0]{headers}};
    ok $set_cookie, 'Set-Cookie issued for the freshly minted token';
    like $set_cookie->[1], qr/\Q$seen_token\E/, 'Set-Cookie carries the same token stashed in scope';
};

subtest "CSRF enforce => 'app' stashes the existing COOKIE token, not a new one" => sub {
    my $mw = PAGI::Middleware::CSRF->new(secret => 'test-secret', enforce => 'app');

    # First, a GET establishes a cookie token.
    my $cookie_token;
    my $get_app = async sub  {
        my ($scope, $receive, $send) = @_;
        await $send->({ type => 'http.response.start', status => 200, headers => [] });
        await $send->({ type => 'http.response.body', body => 'OK', more => 0 });
    };
    my @sent1;
    run_async(async sub {
        await $mw->wrap($get_app)->(
            { type => 'http', path => '/', method => 'GET', headers => [] },
            async sub { { type => 'http.disconnect' } },
            async sub  {
        my ($event) = @_; push @sent1, $event },
        );
    });
    for my $h (@{$sent1[0]{headers}}) {
        if (lc($h->[0]) eq 'set-cookie' && $h->[1] =~ /csrf_token=([^;]+)/) {
            $cookie_token = $1;
        }
    }
    ok $cookie_token, 'cookie token issued on GET';

    # Now an unsafe POST with no submitted token at all (app owns validation) --
    # scope must carry the SAME cookie token, unchanged, not a regenerated one.
    my $seen_token;
    my $post_app = async sub  {
        my ($scope, $receive, $send) = @_;
        $seen_token = $scope->{csrf_token};
        await $send->({ type => 'http.response.start', status => 200, headers => [] });
        await $send->({ type => 'http.response.body', body => 'Created', more => 0 });
    };

    my @sent2;
    run_async(async sub {
        await $mw->wrap($post_app)->(
            {
                type    => 'http',
                path    => '/submit',
                method  => 'POST',
                headers => [['cookie', "csrf_token=$cookie_token"]],
            },
            async sub { { type => 'http.disconnect' } },
            async sub  {
        my ($event) = @_; push @sent2, $event },
        );
    });

    is $sent2[0]{status}, 200, 'app mode never auto-rejects';
    is $seen_token, $cookie_token, 'scope carries the COOKIE token, not a freshly minted one';

    my @set_cookie = grep { lc($_->[0]) eq 'set-cookie' } @{$sent2[0]{headers}};
    is scalar(@set_cookie), 0, 'no Set-Cookie re-issued when the cookie token already existed';
};

subtest 'CSRF cookie has no Secure attribute by default' => sub {
    my $mw = PAGI::Middleware::CSRF->new(secret => 'test-secret');

    my $app = async sub  {
        my ($scope, $receive, $send) = @_;
        await $send->({ type => 'http.response.start', status => 200, headers => [] });
        await $send->({ type => 'http.response.body', body => 'OK', more => 0 });
    };

    my @sent;
    run_async(async sub {
        await $mw->wrap($app)->(
            { type => 'http', path => '/', method => 'GET', headers => [] },
            async sub { { type => 'http.disconnect' } },
            async sub  {
        my ($event) = @_; push @sent, $event },
        );
    });

    my ($set_cookie) = grep { lc($_->[0]) eq 'set-cookie' } @{$sent[0]{headers}};
    ok $set_cookie, 'cookie issued';
    unlike $set_cookie->[1], qr/;\s*Secure/, 'no Secure attribute by default (would break plain-http dev usage)';
};

subtest "CSRF cookie includes Secure attribute when secure => 1" => sub {
    my $mw = PAGI::Middleware::CSRF->new(secret => 'test-secret', secure => 1);

    my $app = async sub  {
        my ($scope, $receive, $send) = @_;
        await $send->({ type => 'http.response.start', status => 200, headers => [] });
        await $send->({ type => 'http.response.body', body => 'OK', more => 0 });
    };

    my @sent;
    run_async(async sub {
        await $mw->wrap($app)->(
            { type => 'http', path => '/', method => 'GET', headers => [] },
            async sub { { type => 'http.disconnect' } },
            async sub  {
        my ($event) = @_; push @sent, $event },
        );
    });

    my ($set_cookie) = grep { lc($_->[0]) eq 'set-cookie' } @{$sent[0]{headers}};
    ok $set_cookie, 'cookie issued';
    like $set_cookie->[1], qr/;\s*Secure/, 'Secure attribute present when configured';
};

done_testing;
