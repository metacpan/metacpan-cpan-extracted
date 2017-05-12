#!/usr/bin/perl
use strict;
use Test::More;
use Plack::Test;
use Plack::Builder;
use Plack::Request;
use HTTP::Request::Common;

sub run {
    my (
        $proxy_addr, $proxy_header,
        $trusted_header, $trusted_proxy,
        $expected
    ) = @_;

    my $app = builder {
        enable sub {
            my $app = shift;
            sub { $_[0]->{REMOTE_ADDR} = $proxy_addr; $app->($_[0]) }; # mock remote address
        };
        enable 'Plack::Middleware::RealIP', header => $trusted_header, trusted_proxy => $trusted_proxy;
        sub { return [ 200, [ 'Content-Type' => 'text/plain' ], [ $_[0]->{REMOTE_ADDR} . '|' . (Plack::Request->new($_[0])->header($trusted_header) || '') ] ] };
    };

    test_psgi $app, sub {
        my $cb = shift;
        my $res = $cb->(GET '/', %{ $proxy_header });
        is $res->content, $expected;
    };
}

run('1.2.3.4',   {'X-Client-IP' => '9.8.7.6'},                'X-Client-IP',     '127.0.0.1', '1.2.3.4|9.8.7.6');
run('1.2.3.4',   {'X-Client-IP' => '9.8.7.6'},                'X-Client-IP',     '1.2.3.4', '9.8.7.6|');
run('1.2.3.4',   {'X-Client-IP' => '9.8.7.6'},                'X-Forwarded-For', '1.2.3.4', '1.2.3.4|');
run('1.2.3.4',   {'X-Client-IP' => '9.8.7.6'},                'X-Forwarded-For', '127.0.0.1', '1.2.3.4|');
run('127.0.0.1', {'X-Forwarded-For' => '9.8.7.6'},            'X-Forwarded-For', '127.0.0.1', '9.8.7.6|');
run('127.0.0.1', {'X-Forwarded-For' => '10.55.1.2, 9.8.7.6'}, 'X-Forwarded-For', '127.0.0.1', '9.8.7.6|10.55.1.2');
run('127.0.0.1', {'X-Forwarded-For' => '10.55.1.2, 9.8.7.6'}, 'X-Forwarded-For', ['127.0.0.1', '9.8/16'], '10.55.1.2|');
run('1.2.3.4',   {'X-Forwarded-For' => '10.55.1.2, 9.8.7.6'}, 'X-Forwarded-For', ['127.0.0.1', '9.8/16'], '1.2.3.4|10.55.1.2, 9.8.7.6');
run('1.2.3.4',   {'X-Forwarded-For' => '10.55.1.2, 9.8.7.6'}, 'X-Forwarded-For', ['127.0.0.1', '9.8/16', '10.55/16'], '1.2.3.4|10.55.1.2, 9.8.7.6');
run('1.2.3.4',   {'X-Forwarded-For' => '10.55.1.2, 9.8.7.6'}, 'X-Forwarded-For', ['127.0.0.1', '9.8/16', '10.55/16', '1.2.3.4'], '1.2.3.4|');

done_testing;
