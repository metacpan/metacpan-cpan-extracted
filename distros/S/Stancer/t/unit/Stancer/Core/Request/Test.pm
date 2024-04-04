package Stancer::Core::Request::Test;

use 5.020;
use strict;
use warnings;
use base qw(Test::Class);

use Config qw(%Config);
use English qw(-no_match_vars);
use TestCase qw(:lwp); # Must be called first to initialize logs
use Stancer::Config;
use Stancer::Core::Object;
use Stancer::Core::Object::Stub;
use Stancer::Core::Request;
use List::MoreUtils ();

## no critic (RequireExtendedFormatting, RequireFinalReturn, ValuesAndExpressions::RequireInterpolationOfMetachars)

sub instanciate : Test {
    my $object = Stancer::Core::Request->new;

    isa_ok($object, 'Stancer::Core::Request', 'Stancer::Core::Request->new()');
}

sub del : Tests(10) {
    my $request = Stancer::Core::Request->new;
    my $id = random_string(29);
    my $object = Stancer::Core::Object::Stub->new($id);
    my $string = random_string(10);
    my $content = random_string(100);

    $object->string($string);

    $mock_ua->clear();

    $mock_response->set_true(qw(is_success));
    $mock_response->set_always(decoded_content => $content);

    is($request->del($object), $content, 'Should return response content');

    my $agent = sprintf 'libwww-perl/%s libstancer-perl/%s (%s %s; perl %vd)', (
        $LWP::VERSION,
        $Stancer::Config::VERSION,
        $Config{osname},
        $Config{archname},
        $PERL_VERSION,
    );

    is($mock_ua->agent, $agent, 'Should have indicate lib version');

    my $req_args = $mock_request->new_args;

    is($req_args->[1], 'DELETE', 'Should create a new DELETE request');
    is($req_args->[2], $object->uri, 'Should use object location');

    my $expected_calls = {
        header => {
            message => 'Should have modified headers',
            args => [
                q//,
                'Content-Type',
                'application/json',
            ],
        },
        authorization_basic => {
            message => 'Should have modified credential',
            args => [],
        },
    };

    while (my ($method, $args) = $mock_request->next_call()) {
        if (List::MoreUtils::any { $_ eq $method } keys %{$expected_calls}) {
            my $message = $expected_calls->{$method}->{message};
            my $expected = $expected_calls->{$method}->{args};
            my $max = scalar @{$expected} - 1;

            for (1..$max) {
                is($args->[$_], $expected->[$_], $message . ' (args ' . $_ . ')');
            }
        }
    }

    while (my ($method, $args) = $mock_ua->next_call()) {
        if ($method eq 'timeout') {
            is($args->[1], Stancer::Config->init->timeout, 'Should have modified timeout');
        }
    }

    my $messages = $log->msgs;

    is(scalar @{$messages}, 1, 'Should have only one logged message');
    is($messages->[0]->{level}, 'debug', 'Should be a debug message');
    is($messages->[0]->{message}, 'API call: DELETE ' . $object->uri, 'Should indicate an API call');
}

sub get : Tests(20) {
    my $request = Stancer::Core::Request->new;
    my $object = Stancer::Core::Object->new;
    my $content = random_string(100);

    $mock_response->set_true(qw(is_success));
    $mock_response->set_always(decoded_content => $content);
    $mock_ua->clear();

    is($request->get($object), $content, 'Should return response content');

    my $agent = sprintf 'libwww-perl/%s libstancer-perl/%s (%s %s; perl %vd)', (
        $LWP::VERSION,
        $Stancer::Config::VERSION,
        $Config{osname},
        $Config{archname},
        $PERL_VERSION,
    );

    is($mock_ua->agent, $agent, 'Should have indicate lib version');

    my $req_args = $mock_request->new_args;

    is($req_args->[1], 'GET', 'Should create a new GET request');
    is($req_args->[2], $object->uri, 'Should use object location');

    my $expected_calls = {
        header => {
            message => 'Should have modified headers',
            args => [
                q//,
                'Content-Type',
                'application/json',
            ],
        },
        authorization_basic => {
            message => 'Should have modified credential',
            args => [],
        },
    };

    while (my ($method, $args) = $mock_request->next_call()) {
        if (List::MoreUtils::any { $_ eq $method } keys %{$expected_calls}) {
            my $message = $expected_calls->{$method}->{message};
            my $expected = $expected_calls->{$method}->{args};
            my $max = scalar @{$expected} - 1;

            for (1..$max) {
                is($args->[$_], $expected->[$_], $message . ' (args ' . $_ . ')');
            }
        }
    }

    while (my ($method, $args) = $mock_ua->next_call()) {
        if ($method eq 'timeout') {
            is($args->[1], Stancer::Config->init->timeout, 'Should have modified timeout');
        }
    }

    my $messages = $log->msgs;

    is(scalar @{$messages}, 1, 'Should have only one logged message');
    is($messages->[0]->{level}, 'debug', 'Should be a debug message');
    is($messages->[0]->{message}, 'API call: GET ' . $object->uri, 'Should indicate an API call');

    # With query params
    my $key1 = random_string(5);
    my $value1 = random_string(15);
    my $key2 = random_string(5);
    my $value2 = random_string(15);
    my $uri = $object->uri;

    # As a hash
    my %query = (
        $key1 => $value1,
        $key2 => $value2,
    );

    $mock_ua->clear();

    is($request->get($object, %query), $content, 'Should return response content (Query as an hash)');

    $req_args = $mock_request->new_args;

    is($req_args->[1], 'GET', 'Should create a new GET request (Query as an hash)');
    like($req_args->[2], qr/^$uri?/sm, 'Should use object location (Query as an hash)');
    like($req_args->[2], qr/$key1=$value1/sm, 'Should use query params (key/value 1 - Query as an hash)');
    like($req_args->[2], qr/$key2=$value2/sm, 'Should use query params (key/value 2 - Query as an hash)');

    # As a hash ref
    my $query = {
        $key1 => $value1,
        $key2 => $value2,
    };

    $mock_ua->clear();

    is($request->get($object, $query), $content, 'Should return response content');

    $req_args = $mock_request->new_args;

    is($req_args->[1], 'GET', 'Should create a new GET request (Query as an hash ref)');
    like($req_args->[2], qr/^$uri?/sm, 'Should use object location (Query as an hash ref)');
    like($req_args->[2], qr/$key1=$value1/sm, 'Should use query params (key/value 1 - Query as an hash ref)');
    like($req_args->[2], qr/$key2=$value2/sm, 'Should use query params (key/value 2 - Query as an hash ref)');
}

sub patch : Tests(11) {
    my $request = Stancer::Core::Request->new;
    my $id = random_string(29);
    my $object = Stancer::Core::Object::Stub->new($id);
    my $string = random_string(10);
    my $content = random_string(100);

    $mock_ua->clear();

    $object->string($string);

    $mock_response->set_true(qw(is_success));
    $mock_response->set_always(decoded_content => $content);

    is($request->patch($object), $content, 'Should return response content');

    my $agent = sprintf 'libwww-perl/%s libstancer-perl/%s (%s %s; perl %vd)', (
        $LWP::VERSION,
        $Stancer::Config::VERSION,
        $Config{osname},
        $Config{archname},
        $PERL_VERSION,
    );

    is($mock_ua->agent, $agent, 'Should have indicate lib version');

    my $req_args = $mock_request->new_args;

    is($req_args->[1], 'PATCH', 'Should create a new PATCH request');
    is($req_args->[2], $object->uri, 'Should use object location');

    my $expected_calls = {
        content => {
            message => 'Should have a content',
            args => [
                q//,
                '{"string":"' . $string . '"}',
            ],
        },
        header => {
            message => 'Should have modified headers',
            args => [
                q//,
                'Content-Type',
                'application/json',
            ],
        },
        authorization_basic => {
            message => 'Should have modified credential',
            args => [],
        },
    };

    while (my ($method, $args) = $mock_request->next_call()) {
        if (List::MoreUtils::any { $_ eq $method } keys %{$expected_calls}) {
            my $message = $expected_calls->{$method}->{message};
            my $expected = $expected_calls->{$method}->{args};
            my $max = scalar @{$expected} - 1;

            for (1..$max) {
                is($args->[$_], $expected->[$_], $message . ' (args ' . $_ . ')');
            }
        }
    }

    while (my ($method, $args) = $mock_ua->next_call()) {
        if ($method eq 'timeout') {
            is($args->[1], Stancer::Config->init->timeout, 'Should have modified timeout');
        }
    }

    my $messages = $log->msgs;

    is(scalar @{$messages}, 1, 'Should have only one logged message');
    is($messages->[0]->{level}, 'debug', 'Should be a debug message');
    is($messages->[0]->{message}, 'API call: PATCH ' . $object->uri, 'Should indicate an API call');
}

sub post : Tests(11) {
    my $request = Stancer::Core::Request->new;
    my $object = Stancer::Core::Object::Stub->new;
    my $string = random_string(10);
    my $content = random_string(100);
    my $base_agent = random_string(100);
    my $agent = sprintf 'libwww-perl/%s libstancer-perl/%s (%s %s; perl %vd)', (
        $LWP::VERSION,
        $Stancer::Config::VERSION,
        $Config{osname},
        $Config{archname},
        $PERL_VERSION,
    );

    $mock_ua->clear();

    $object->string($string);

    $mock_response->set_true(qw(is_success));
    $mock_response->set_always(decoded_content => $content);

    $mock_ua->agent($base_agent);

    is($request->post($object), $content, 'Should return response content');

    is($mock_ua->agent, $agent, 'Should have indicate lib version');

    my $req_args = $mock_request->new_args;

    is($req_args->[1], 'POST', 'Should create a new POST request');
    is($req_args->[2], $object->uri, 'Should use object location');

    my $expected_calls = {
        content => {
            message => 'Should have a content',
            args => [
                q//,
                '{"string":"' . $string . '"}',
            ],
        },
        header => {
            message => 'Should have modified headers',
            args => [
                q//,
                'Content-Type',
                'application/json',
            ],
        },
        authorization_basic => {
            message => 'Should have modified credential',
            args => [],
        },
    };

    while (my ($method, $args) = $mock_request->next_call()) {
        if (List::MoreUtils::any { $_ eq $method } keys %{$expected_calls}) {
            my $message = $expected_calls->{$method}->{message};
            my $expected = $expected_calls->{$method}->{args};
            my $max = scalar @{$expected} - 1;

            for (1..$max) {
                is($args->[$_], $expected->[$_], $message . ' (args ' . $_ . ')');
            }
        }
    }

    while (my ($method, $args) = $mock_ua->next_call()) {
        if ($method eq 'timeout') {
            is($args->[1], Stancer::Config->init->timeout, 'Should have modified timeout');
        }
    }

    my $messages = $log->msgs;

    is(scalar @{$messages}, 1, 'Should have only one logged message');
    is($messages->[0]->{level}, 'debug', 'Should be a debug message');
    is($messages->[0]->{message}, 'API call: POST ' . $object->uri, 'Should indicate an API call');
}

sub request_errors : Tests(49) {
    my $request = Stancer::Core::Request->new;
    my $key = 'pprod_' . random_string(25);
    my $object = Stancer::Core::Object->new;
    my $config = Stancer::Config->init;

    $mock_response->set_false(qw(is_success));
    $mock_response->set_always(decoded_content => undef);

    my @errors = (
        {
            code => 400,
            name => 'Stancer::Exceptions::Http::BadRequest',
            message => 'Should throw a BadRequest (400) error',
            level => 'critical',
        },
        {
            code => 401,
            name => 'Stancer::Exceptions::Http::Unauthorized',
            message => 'Should throw a Unauthorized (401) error',
            level => 'critical',
        },
        {
            code => 404,
            name => 'Stancer::Exceptions::Http::NotFound',
            message => 'Should throw a NotFound (404) error',
            level => 'error',
        },
        {
            code => 409,
            name => 'Stancer::Exceptions::Http::Conflict',
            message => 'Should throw a Conflict (409) error',
            level => 'error',
        },
        {
            code => 410,
            name => 'Stancer::Exceptions::Http::ClientSide',
            message => 'Should throw a client side HTTP error if not already handled',
            level => 'error',
        },
        {
            code => 500,
            name => 'Stancer::Exceptions::Http::InternalServerError',
            message => 'Should throw an Internal Server Error (500) error',
            level => 'critical',
        },
        {
            code => 501,
            name => 'Stancer::Exceptions::Http::ServerSide',
            message => 'Should throw a server side HTTP error if not already handled',
            level => 'critical',
        },
    );

    foreach my $error (@errors) {
        note 'HTTP ' . $error->{code};

        $mock_response->set_always( code => $error->{code} );
        $log->clear();

        $config->debug(random_integer(0, 1));
        splice @{$config->calls}; # Do not do this at home kids

        throws_ok(sub { $request->get($object) }, $error->{name}, $error->{message});

        my $exception = $EVAL_ERROR;
        my $log_message = sprintf 'HTTP %d - %s', $error->{code}, $exception->message;
        my $messages = $log->msgs;
        my $tmp = 'Should be a' . ($error->{level} eq 'error' ? 'n error' : q/ / . $error->{level}) . ' message';

        is(scalar @{$messages}, 2, 'Should have two logged messages'); # the first one is the API call
        is($messages->[1]->{level}, $error->{level}, $tmp);
        is($messages->[1]->{message}, $log_message, 'Should indicate HTTP status code and reason');

        is($exception->request, $mock_request, 'Should have the request');
        is($exception->response, $mock_response, 'Should have the response');

        if ($config->debug) {
            cmp_deeply($config->last_call, noclass({
                request => $mock_request,
                response => $mock_response,
                exception => $exception,
            }), 'Last call should have request, response and exception');
        } else {
            is($config->last_call, undef, 'No calls without debug mode');
        }
    }
}

sub request_errors_message : Tests(14) {
    my $request = Stancer::Core::Request->new;
    my $object = Stancer::Core::Object->new;

    $mock_response->set_false(qw(is_success));
    $mock_response->set_always(code => 400);

    my $with_message = {
        error => {
            message => random_string(10),
        },
    };
    my $with_error = {
        error => {
            message => {
                error => random_string(10),
            },
        },
    };
    my $with_error_and_id = {
        error => {
            message => {
                error => random_string(10),
                id => random_string(10),
            },
        },
    };
    my $with_id = {
        error => {
            message => {
                id => random_string(10),
            },
        },
    };

    my @errors = ( # 7 items
        {
            message => 'With undef',
            return => undef,
            expected => 'Bad Request',
        },
        {
            message => 'With a string',
            return => random_string(10),
            expected => 'Bad Request',
        },
        {
            message => 'With a JSON without error',
            return => encode_json {string => random_string(10)},
            expected => 'Bad Request',
        },
        {
            message => 'With a JSON with an error message',
            return => encode_json $with_message,
            expected => $with_message->{error}->{message},
        },
        {
            message => 'With a JSON with a complex error message',
            return => encode_json $with_error,
            expected => $with_error->{error}->{message}->{error},
        },
        {
            message => 'With a JSON with a complex error message with id',
            return => encode_json $with_error_and_id,
            expected => $with_error_and_id->{error}->{message}->{error} . q/ (/ . $with_error_and_id->{error}->{message}->{id} . q/)/,
        },
        {
            message => 'With a JSON with an id',
            return => encode_json $with_id,
            expected => $with_id->{error}->{message}->{id},
        },
    );

    foreach my $error (@errors) { # 2 tests
        note $error->{message};

        $mock_response->set_always(decoded_content => $error->{'return'});

        throws_ok(
            sub { $request->get($object) },
            'Stancer::Exceptions::Http::BadRequest',
            'Should throw an exception',
        );

        my $exception = $EVAL_ERROR;

        is($exception->message, $error->{expected}, 'Should have expected message');
    }
}

1;
