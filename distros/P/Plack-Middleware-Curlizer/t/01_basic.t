use strict;
use Plack::Builder;
use HTTP::Request::Common;
use LWP::UserAgent;

use Test::More;
use Plack::Test;

use Plack::Middleware::Curlizer;

can_ok 'Plack::Middleware::Curlizer', qw/new/;

my $PSGI_ENV_KEY = 'psgix.req_curl';

my $app = builder {
    enable 'Curlizer', callback => sub {
        my ($curl, $req, $env) = @_;
        $env->{$PSGI_ENV_KEY} = $curl;
    };
    sub {
        my ($env) = @_;
        [ 200, ['Content-Type' => 'text/plain'], [$env->{$PSGI_ENV_KEY}] ];
    };
};

GET: {
    my $cli = sub {
            my $cb = shift;
            my $res = $cb->(GET '/');
            is $res->code, 200;
            is $res->content_type, 'text/plain';
            like $res->content, qr/^curl /;
            note $res->content if $ENV{AUTHOR_TEST};
    };
    test_psgi $app, $cli;
}

POST: {
    my $cli = sub {
            my $cb = shift;
            my $res = $cb->(POST '/', [ foo => 123, bar => '`ls`' ]);
            is $res->code, 200;
            is $res->content_type, 'text/plain';
            like $res->content, qr/^curl /;
            note $res->content if $ENV{AUTHOR_TEST};
    };
    test_psgi $app, $cli;
}

done_testing;
