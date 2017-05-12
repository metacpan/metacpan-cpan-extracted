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
      font_path => './font/MTLmr3m.ttf',
      max_width => 10, max_height => 200;
};

test_psgi $handler, sub {
    my $cb = shift;

    subtest 'Beyond max width' => sub {
        my $res = $cb->(GET "http://localhost/images/30x1.png");
        is $res->code, 500, 'Response HTTP status';
    };

    subtest 'Beyond max height' => sub {
        my $res = $cb->(GET "http://localhost/images/1x300.png");
        is $res->code, 500, 'Response HTTP status';
    };

    subtest 'Equal max width' => sub {
        my $res = $cb->(GET "http://localhost/images/10x1.png");
        is $res->code, 200, 'Response HTTP status';
    };

    subtest 'Equal max height' => sub {
        my $res = $cb->(GET "http://localhost/images/1x200.png");
        is $res->code, 200, 'Response HTTP status';
    };
};

done_testing;
