use strict;
use warnings FATAL => 'all';

use Test::More;
use Test::Warnings;
use Test::Fatal;
use Plack::Response 1.0025;
use Plack::Test;
use HTTP::Request::Common;

my $global_time;
BEGIN {
    # we need to override this builtin before loading modules that use it.
    $global_time = '1356998400';  # 2013-01-01
    *CORE::GLOBAL::time = sub() { return $global_time };
}

use Plack::Middleware::ServerStatus::Tiny;

my $app = Plack::Response->new(200, [], 'oh hai')->to_app;

like(
    exception { Plack::Middleware::ServerStatus::Tiny->wrap },
    qr/^missing required option: 'path'/,
    '\'path\' is required',
);

# TODO: test for the warning message on missing leading /

{
    my $app = Plack::Middleware::ServerStatus::Tiny->wrap($app, path => '/status');

    test_psgi $app, sub {
        my $cb = shift;

        test_response(
            $cb->(GET '/status'),
            [
                '200',
                [
                    'Content-Type' => 'text/plain',
                    'Content-Length' => 26,
                ],
                [ 'uptime: 0; access count: 1' ],
            ],
            'first hit',
        );

        test_response(
            $cb->(GET '/status'),
            [
                '200',
                [
                    'Content-Type' => 'text/plain',
                    'Content-Length' => 26,
                ],
                [ 'uptime: 0; access count: 2' ],
            ],
            'second hit',
        );

        $global_time += 2;

        test_response(
            $cb->(GET '/hello'),
            [
                '200',
                [],
                [ 'oh hai' ],
            ],
            'time passes; third hit',
        );

        $global_time += 30;

        test_response(
            $cb->(GET '/status'),
            [
                '200',
                [
                    'Content-Type' => 'text/plain',
                    'Content-Length' => 27,
                ],
                [ 'uptime: 32; access count: 4' ],
            ],
            'time passes; fourth hit',
        );
    };
}

done_testing;

# TODO: release as its own Plack helper dist
use Test::Deep;
use Test::Deep::UnorderedPairs;
sub test_response
{
    my ($response, $e_psgi_response, $name) = @_;

    local $Test::Builder::Level = $Test::Builder::Level + 1;
    # TODO: use //
    $name = 'PSGI response' if not defined $name;

    subtest $name => sub
    {
        is(
            $response->code,
            $e_psgi_response->[0],
            $name . ' status',
        );

        # this only checks the subset of headers specified in the expected
        # response
        cmp_deeply(
            $response->headers,
            # TODO: use //
            tuples(@{ $_->[1] || {} }),
            $name . ' headers',
        ),

        die 'specifying multiple elements in expected PSGI response body not supported'
            if @{$e_psgi_response->[2]} > 1;
        cmp_deeply(
            $response->content,
            # TODO: use //
            ($e_psgi_response->[2][0] || ''),
            $name . ' body',
        );
    };
}
