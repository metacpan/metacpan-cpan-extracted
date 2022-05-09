use strict;
use warnings;
use Test::More;
use Plack::Test;
use Plack::Builder;
use HTTP::Request::Common;

subtest 'no Content-Type' => sub {
    my $app = builder {
        enable 'SecureHeaders';
        sub { [ 200, [ ], ['HELLO WORLD'] ] };
    };

    test_psgi $app, sub {
        my $cb  = shift;
        my $res = $cb->(GET '/');
        is $res->code, 500, 'response status 500';
        like $res->content, qr/^Required Content-Type header/, 'content include error message';
    };
};

subtest 'text/html required charset' => sub {
    my $app = builder {
        enable 'SecureHeaders';
        sub { [ 200, ['Content-Type' => 'text/html'], ['HELLO WORLD'] ] };
    };

    test_psgi $app, sub {
        my $cb  = shift;
        my $res = $cb->(GET '/');
        is $res->code, 500, 'response status 500';
        like $res->content, qr/^Required charset for text\/html/, 'content include error message';
    };

    my $app_with_charset = builder {
        enable 'SecureHeaders';
        sub { [ 200, ['Content-Type' => 'text/html; charset=utf-8'], ['HELLO WORLD'] ] };
    };

    test_psgi $app_with_charset, sub {
        my $cb  = shift;
        my $res = $cb->(GET '/');
        is $res->code, 200, 'response status 200';
        is $res->content, 'HELLO WORLD';
    };
};

done_testing;
