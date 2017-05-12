use strict;
use warnings;
use Test::More;
use Plack::Middleware::Static;
use Plack::Builder;
use Plack::Util;
use HTTP::Request::Common;
use HTTP::Response;
use Plack::Test;
use Data::Dumper;
use CHI;

my $handler = builder {
    my $chi = CHI->new(
        driver => 'Memory',
        global => 1,
    );
    enable 'Cache::CHI', chi => $chi, rules => [
        qr{^/api/}          => undef,
        qr{\.(jpg|png)$}    => { expires_in => '5 min' },
    ], scrub => [ 'Set-Cookie' ], cachequeries => 1;
    enable 'Static', path => qr{^/images/}, root => 't';
    sub { [
        404,
        [ 'Content-Type' => 'text/plain', 'Content-Length' => 8 ],
        [ 'not found' ]
    ] };
};

test_psgi $handler, sub {
    my $cb = shift;

    subtest 'Request not matcing the rules' => sub {

        my $res = $cb->(GET "http://localhost/");
        is $res->code, 404, 'Response HTTP status';
        is $res->content_type, 'text/plain', 'Response Content-Type';
        is $res->content, 'not found', 'Response body';
        is $res->header('X-Plack-Cache'), 'lookup, pass', 'Cache action trace';
    };

    subtest 'Request matching the rules' => sub {

        subtest 'Existing image, 1st request' => sub {
            my $res = $cb->(GET "http://localhost/images/100x100.png");
            is $res->code, 200, 'Response HTTP status';
            is $res->content_type, 'image/png', 'Response Content-Type';
            is $res->header('X-Plack-Cache'), 'lookup, fetch, miss, delegate, pass, store', 'Cache action trace';
        };

        subtest 'Existing image, 2nd request' => sub {
            my $res = $cb->(GET "http://localhost/images/100x100.png");
            is $res->code, 200, 'Response HTTP status';
            is $res->content_type, 'image/png', 'Response Content-Type';
            is $res->header('X-Plack-Cache'), 'lookup, fetch, hit', 'Cache action trace';
        };

        subtest 'Non-existing image, 1st request' => sub {
            my $res = $cb->(GET "http://localhost/images/nonexisting.png");
            is $res->code, 404, 'Response HTTP status';
            is $res->header('X-Plack-Cache'), 'lookup, fetch, miss, delegate, pass, store', 'Cache action trace';
        };

        subtest 'Non-existing image, 2nd request' => sub {
            my $res = $cb->(GET "http://localhost/images/nonexisting.png");
            is $res->code, 404, 'Response HTTP status';
            is $res->header('X-Plack-Cache'), 'lookup, fetch, hit', 'Cache action trace';
        };

    };

};

done_testing;

