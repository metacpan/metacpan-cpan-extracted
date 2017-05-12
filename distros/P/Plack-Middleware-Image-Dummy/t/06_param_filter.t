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

our $param_filter;

sub param_filter {
    $param_filter->($_[0]);
}

my $handler = builder {
    enable 'Image::Dummy', map_path => qr{^/images/},
      font_path => './font/MTLmr3m.ttf', param_filter => \&param_filter;
};

test_psgi $handler, sub {
    my $cb = shift;

    subtest 'As is' => sub {
        local $param_filter = sub {
            $_[0];
        };
        my $res = $cb->(GET "http://localhost/images/100x100.png");
        is $res->code, 200, 'Response HTTP status';
    };

    subtest 'Stop!' => sub {
        local $param_filter = sub {
            undef;
        };
        my $res = $cb->(GET "http://localhost/images/100x100.png");
        is $res->code, 404, 'Response HTTP status';
    };
};

done_testing;
