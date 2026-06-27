#!/usr/bin/env perl
use strict;
use warnings;
use Test2::V0;
use Future::AsyncAwait;

use lib 'lib';
use PAGI::Test::Client;

# App that throws an exception
my $broken_app = async sub {
    my ($scope, $receive, $send) = @_;
    die "Something went terribly wrong at line 42\n";
};

# App that works normally
my $working_app = async sub {
    my ($scope, $receive, $send) = @_;

    await $send->({
        type    => 'http.response.start',
        status  => 200,
        headers => [['content-type', 'text/plain']],
    });

    await $send->({
        type => 'http.response.body',
        body => 'OK',
        more => 0,
    });
};

# =============================================================================
# Default behavior: trap exceptions, return 500
# =============================================================================

subtest 'default: exception trapped, returns 500' => sub {
    my $client = PAGI::Test::Client->new(app => $broken_app);
    my $res = $client->get('/');

    is $res->status, 500, 'status is 500';
    is $res->text, 'Internal Server Error', 'body is error message';
    is $res->header('content-type'), 'text/plain', 'content-type is text/plain';
    like $res->exception, qr/Something went terribly wrong/, 'exception captured';
};

subtest 'default: working app has no exception' => sub {
    my $client = PAGI::Test::Client->new(app => $working_app);
    my $res = $client->get('/');

    is $res->status, 200, 'status is 200';
    is $res->text, 'OK', 'body is OK';
    ok !defined $res->exception, 'no exception';
};

subtest 'default: can use is_error on 500 response' => sub {
    my $client = PAGI::Test::Client->new(app => $broken_app);
    my $res = $client->get('/');

    ok $res->is_error, 'is_error is true';
    ok !$res->is_success, 'is_success is false';
};

# =============================================================================
# Explicit raise_app_exceptions => 0 (same as default)
# =============================================================================

subtest 'raise_app_exceptions => 0: exception trapped' => sub {
    my $client = PAGI::Test::Client->new(
        app => $broken_app,
        raise_app_exceptions => 0,
    );
    my $res = $client->get('/');

    is $res->status, 500, 'status is 500';
    like $res->exception, qr/Something went terribly wrong/, 'exception captured';
};

# =============================================================================
# raise_app_exceptions => 1: propagate exceptions
# =============================================================================

subtest 'raise_app_exceptions => 1: exception propagates' => sub {
    my $client = PAGI::Test::Client->new(
        app => $broken_app,
        raise_app_exceptions => 1,
    );

    my $died = 0;
    my $error;
    eval {
        $client->get('/');
    };
    if ($@) {
        $died = 1;
        $error = $@;
    }

    ok $died, 'request died';
    like $error, qr/Something went terribly wrong/, 'got original exception';
};

subtest 'raise_app_exceptions => 1: working app still works' => sub {
    my $client = PAGI::Test::Client->new(
        app => $working_app,
        raise_app_exceptions => 1,
    );
    my $res = $client->get('/');

    is $res->status, 200, 'status is 200';
    is $res->text, 'OK', 'body is OK';
};

# =============================================================================
# Different HTTP methods with exceptions
# =============================================================================

subtest 'exception handling works for all HTTP methods' => sub {
    my $client = PAGI::Test::Client->new(app => $broken_app);

    for my $method (qw(get post put patch delete head options)) {
        my $res = $client->$method('/');
        is $res->status, 500, "$method returns 500 on exception";
        ok defined $res->exception, "$method captures exception";
    }
};

# =============================================================================
# Exception with partial response (edge case)
# =============================================================================

subtest 'exception after response started' => sub {
    my $partial_app = async sub {
        my ($scope, $receive, $send) = @_;

        # Start response
        await $send->({
            type    => 'http.response.start',
            status  => 200,
            headers => [['content-type', 'text/plain']],
        });

        # Then die
        die "Oops, died mid-response\n";
    };

    my $client = PAGI::Test::Client->new(app => $partial_app);
    my $res = $client->get('/');

    # Should still get 500 since we trap before building response
    is $res->status, 500, 'status is 500 even if response started';
    like $res->exception, qr/Oops, died mid-response/, 'exception captured';
};

# =============================================================================
# Test: App returns without sending response (common async mistake)
# =============================================================================

subtest 'app returns without sending response dies' => sub {
    my $empty_app = async sub {
        my ($scope, $receive, $send) = @_;
        # Forgot to send anything!
        return;
    };

    my $client = PAGI::Test::Client->new(app => $empty_app);

    my $died = 0;
    my $error;
    eval {
        $client->get('/');
    };
    if ($@) {
        $died = 1;
        $error = $@;
    }

    ok $died, 'request died when no response sent';
    like $error, qr/App returned without sending response/, 'error message is helpful';
    like $error, qr/await/, 'error mentions await';
};

subtest 'app with only response.start (no body) still works' => sub {
    # Edge case: response.start sent but no body - this should work
    # (some responses like 204 No Content don't need a body)
    my $start_only_app = async sub {
        my ($scope, $receive, $send) = @_;

        await $send->({
            type    => 'http.response.start',
            status  => 204,
            headers => [],
        });

        await $send->({
            type => 'http.response.body',
            body => '',
        });
    };

    my $client = PAGI::Test::Client->new(app => $start_only_app);
    my $res = $client->get('/');

    is $res->status, 204, 'status is 204';
};

done_testing;
