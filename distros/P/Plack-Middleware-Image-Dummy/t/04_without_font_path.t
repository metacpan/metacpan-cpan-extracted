# vim: set expandtab ts=4 sw=4 nowrap ft=perl ff=unix :
use strict;
use warnings;
use Test::More;
use Test::Exception;
use Plack::Middleware::Static;
use Plack::Builder;
use Plack::Util;
use HTTP::Request::Common;
use HTTP::Response;
use Plack::Test;

subtest 'Without font path' => sub {
    dies_ok {
        my $handler = builder {
            enable 'Image::Dummy', map_path => '/mount/';
        };
    }
};

done_testing;
