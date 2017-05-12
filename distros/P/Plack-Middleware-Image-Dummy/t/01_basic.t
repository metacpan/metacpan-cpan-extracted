# vim: set expandtab ts=4 sw=4 nowrap ft=perl ff=unix :
use strict;
use warnings;
use Test::More;
use Plack::Middleware::Static;
use Plack::Builder;
use Plack::Util;
use HTTP::Request::Common;
use HTTP::Response;
use Plack::Test;

my $handler = builder {
    enable 'Image::Dummy', map_path => qr{^/images/},
      font_path => './font/MTLmr3m.ttf';
    sub {
        [
            404,
            [ 'Content-Type' => 'text/plain', 'Content-Length' => 8 ],
            ['Pass throught to an application']
        ];
    };
};

test_psgi $handler, sub {
    my $cb = shift;

    subtest 'Pass thru to other application' => sub {
        my $res = $cb->(GET 'http://localhost/');
        is $res->code,         404,          'Response HTTP status';
        is $res->content_type, 'text/plain', 'Response Content-Type';
        is $res->content,      'Not found.', 'Response body';
    };

    subtest 'Basic response' => sub {
        subtest 'Basic image(PNG)' => sub {
            my $res = $cb->(GET "http://localhost/images/100x100.png");
            is $res->code,         200,         'Response HTTP status';
            is $res->content_type, 'image/png', 'Response Content-Type';
        };

        subtest 'Basic image(JPEG)' => sub {
            my $res = $cb->(GET "http://localhost/images/100x100.jpeg");
            is $res->code,         200,          'Response HTTP status';
            is $res->content_type, 'image/jpeg', 'Response Content-Type';
        };

        subtest 'Basic image(JPG)' => sub {
            my $res = $cb->(GET "http://localhost/images/100x100.jpg");
            is $res->code,         200,          'Response HTTP status';
            is $res->content_type, 'image/jpeg', 'Response Content-Type';
        };

        subtest 'Basic image(GIF)' => sub {
            my $res = $cb->(GET "http://localhost/images/100x100.gif");
            is $res->code,         200,         'Response HTTP status';
            is $res->content_type, 'image/gif', 'Response Content-Type';
        };

        subtest 'Error pattern of {width}x{height}.{ext}' => sub {
            my $res = $cb->(GET "http://localhost/images/-11x2121.ping");
            is $res->code, 404, 'Response HTTP status';
        };
    };

    subtest 'With color' => sub {
        my $res =
          $cb->(GET
              "http://localhost/images/100x100.png?color=ff0000&bgcolor=00ff00"
          );
        is $res->code,         200,         'Response HTTP status';
        is $res->content_type, 'image/png', 'Response Content-Type';
    };
};

done_testing;
