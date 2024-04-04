package Stancer::Core::Request::Call::Test;

use 5.020;
use strict;
use warnings;
use base qw(Test::Class);

use HTTP::Request;
use HTTP::Response;
use Stancer::Core::Request::Call;
use Stancer::Exceptions::Throwable;
use TestCase;

## no critic (RequireFinalReturn)

sub exception : Tests(2) {
    my $exception = Stancer::Exceptions::Throwable->new();

    {
        my $call = Stancer::Core::Request::Call->new();

        is($call->exception, undef, 'Should return undef by default');
    }

    {
        my $call = Stancer::Core::Request::Call->new(exception => $exception);

        is($call->exception, $exception, 'Should return exception');
    }
}

sub request : Tests(2) {
    my $request = HTTP::Request->new();

    {
        my $call = Stancer::Core::Request::Call->new();

        is($call->request, undef, 'Should return undef by default');
    }

    {
        my $call = Stancer::Core::Request::Call->new(request => $request);

        is($call->request, $request, 'Should return request');
    }
}

sub response : Tests(2) {
    my $response = HTTP::Response->new();

    {
        my $call = Stancer::Core::Request::Call->new();

        is($call->response, undef, 'Should return undef by default');
    }

    {
        my $call = Stancer::Core::Request::Call->new(response => $response);

        is($call->response, $response, 'Should return response');
    }
}

1;
