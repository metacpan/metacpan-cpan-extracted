use strict;
use warnings;

use Test::More;
use Plack::Test;

use HTTP::Request::Common;
use Plack::Builder;
use Plack::App::EventSource;

subtest 'returns error when not GET' => sub {
    my $app = sub { [200, [], ['Hello']] };

    $app = builder {
        mount '/events' => _build_app();
        mount '/'       => $app
    };

    test_psgi $app, sub {
        my $cb = shift;

        my $res = $cb->(POST '/events');
        is $res->code,    405;
        is $res->content, 'Method not allowed';
    };
};

subtest 'returns data' => sub {
    my $app = sub { [200, [], ['Hello']] };

    $app = builder {
        mount '/events' => _build_app();
        mount '/'       => $app
    };

    test_psgi $app, sub {
        my $cb = shift;

        my $res = $cb->(GET '/events');
        is $res->code,    200;
        is $res->content, "data: foo\r\n\r\n";
    };
};

subtest 'accepts data as a hash ref' => sub {
    my $app = sub { [200, [], ['Hello']] };

    $app = builder {
        mount '/events' => _build_app(
            handler_cb => sub {
                my $conn = shift;
                $conn->push({id => 1, data => 'foo'});
                $conn->close;
            }
        );
        mount '/' => $app
    };

    test_psgi $app, sub {
        my $cb = shift;

        my $res = $cb->(GET '/events');
        is $res->code,    200;
        is $res->content, "id: 1\r\ndata: foo\r\n\r\n";
    };
};

sub _build_app {
    my (%params) = @_;

    return Plack::App::EventSource->new(
        handler_cb => sub {
            my ($conn, $env) = @_;

            $conn->push('foo');
            $conn->close;
        },
        %params
    );
}

done_testing;
