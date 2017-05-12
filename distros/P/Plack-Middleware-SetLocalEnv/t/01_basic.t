use strict;
use warnings;
use Test::More;
use HTTP::Request::Common;
use Plack::Test;
use Plack::Builder;

my $app = sub {
    my %options = @_;
    my $app = builder {
        enable "SetLocalEnv" => %options;
        sub {
            my $env = shift;
            [
                200,
                [ "Content-Type" => "text/plain" ],
                [ map { "$_=$ENV{$_}\n"} sort keys %ENV ],
            ]
        };
    };
};

local $ENV{SET_LOCAL_ENV} = 1;

test_psgi
    app => $app->(),
    client => sub {
        my $client = shift;
        my $res = $client->(GET "/");
        is $res->content_type, 'text/plain';
        like $res->content, qr/^SET_LOCAL_ENV=1$/m;
    };

test_psgi
    app => $app->(
        REQUEST_ID => "HTTP_X_REQUEST_ID",
    ),
    client => sub {
        my $client = shift;
        my $res = $client->(GET "/", "X-Request-ID" => "123456");
        is $res->content_type, 'text/plain';
        like $res->content, qr/^SET_LOCAL_ENV=1$/m;
        like $res->content, qr/^REQUEST_ID=123456$/m;
    };

test_psgi
    app => $app->(
        REQUEST_ID => "HTTP_X_REQUEST_ID",
        URL_SCHEME => "psgi.url_scheme",
    ),
    client => sub {
        my $client = shift;
        my $res = $client->(
            GET "/",
            "X-Request-ID" => "234567",
        );
        is $res->content_type, 'text/plain';
        like $res->content, qr/^SET_LOCAL_ENV=1$/m;
        like $res->content, qr/^REQUEST_ID=234567$/m;
        like $res->content, qr/^URL_SCHEME=http$/m;
    };

test_psgi
    app => $app->(),
    client => sub {
        my $client = shift;
        my $res = $client->(GET "/");
        is $res->content_type, 'text/plain';
        like $res->content, qr/^SET_LOCAL_ENV=1$/m;
        unlike $res->content, qr/^REQUEST_ID=/m;
        unlike $res->content, qr/^URL_SCHEME=/m;
    };

done_testing;
