package Stancer::Exceptions::Http::Test;

use 5.020;
use strict;
use warnings;
use base qw(Test::Class);

use Stancer::Exceptions::Http;
use HTTP::Request;
use HTTP::Response;
use TestCase;

## no critic (RequireFinalReturn, ValuesAndExpressions::RequireInterpolationOfMetachars)

sub factory : Tests(115) {
    my @codes = ();

    push @codes, {
        expected => 'Stancer::Exceptions::Http',
        status => random_integer(100, 399),
    };

    for my $status (400..410) {
        my $expected = 'Stancer::Exceptions::Http::ClientSide';

        $expected = 'Stancer::Exceptions::Http::BadRequest' if $status == 400;
        $expected = 'Stancer::Exceptions::Http::Unauthorized' if $status == 401;
        $expected = 'Stancer::Exceptions::Http::NotFound' if $status == 404;
        $expected = 'Stancer::Exceptions::Http::Conflict' if $status == 409;

        push @codes, {
            expected => $expected,
            status => $status,
        };
    }

    for my $status (500..510) {
        my $expected = 'Stancer::Exceptions::Http::ServerSide';

        $expected = 'Stancer::Exceptions::Http::InternalServerError' if $status == 500;

        push @codes, {
            expected => $expected,
            status => $status,
        };
    }

    for my $data (@codes) { # @codes has 23 elements
        { # 1 test
            note 'With only status (' . $data->{status} . q/)/;

            my $object = Stancer::Exceptions::Http->factory($data->{status});

            isa_ok($object, $data->{expected}, 'Stancer::Exceptions::Http->factory(' . $data->{status} . q/)/);
        }

        { # 2 tests
            note 'With status (' . $data->{status} . ') and an HASH';

            my $message = random_string(20);
            my $object = Stancer::Exceptions::Http->factory($data->{status}, message => $message);

            isa_ok($object, $data->{expected}, 'Stancer::Exceptions::Http->factory(' . $data->{status} . ', message => $message)');
            is($object->message, $message, 'Should have passed arguments');
        }

        { # 2 tests
            note 'With status (' . $data->{status} . ') and an HASHREF';

            my $message = random_string(20);
            my $object = Stancer::Exceptions::Http->factory($data->{status}, { message => $message });

            isa_ok($object, $data->{expected}, 'Stancer::Exceptions::Http->factory(' . $data->{status} . ', { message => $message })');
            is($object->message, $message, 'Should have passed arguments');
        }
    }
}

sub instance : Tests(4) {
    my $object = Stancer::Exceptions::Http->new();

    isa_ok($object, 'Stancer::Exceptions::Http', 'Stancer::Exceptions::Http->new()');
    isa_ok($object, 'Stancer::Exceptions::Throwable', 'Stancer::Exceptions::Http->new()');

    is($object->message, 'HTTP error', 'Has default message');
    is($object->log_level, 'warning', 'Has a log level');
}

sub request : Tests(4) {
    {
        my $object = Stancer::Exceptions::Http->new;

        is($object->request, undef, 'Undefined by default');
    }

    {
        my $request = HTTP::Request->new;
        my $object = Stancer::Exceptions::Http->new(request => $request);

        isa_ok($object->request, 'HTTP::Request', '$object->request');
        is($object->request, $request);

        dies_ok { $object->request($request) } 'Not writable';
    }
}

sub response : Tests(4) {
    {
        my $object = Stancer::Exceptions::Http->new;

        is($object->response, undef, 'Undefined by default');
    }

    {
        my $response = HTTP::Response->new;
        my $object = Stancer::Exceptions::Http->new(response => $response);

        isa_ok($object->response, 'HTTP::Response', '$object->response');
        is($object->response, $response);

        dies_ok { $object->response($response) } 'Not writable';
    }
}

1;
