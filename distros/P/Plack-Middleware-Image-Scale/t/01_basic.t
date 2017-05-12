use strict;
use warnings;
use Test::More;
use Plack::Middleware::Static;
use Plack::Builder;
use Plack::Util;
use HTTP::Request::Common;
use HTTP::Response;
use Plack::Test;
use Image::Scale;
use Imager;
use Data::Dumper;

my $handler = builder {
    enable 'Image::Scale';
    enable 'Static', path => qr{^/images/}, root => 't';
    sub { [
        404,
        [ 'Content-Type' => 'text/plain', 'Content-Length' => 8 ],
        [ 'not found' ]
    ] };
};

test_psgi $handler, sub {
    my $cb = shift;

    subtest 'Fall-thru the middleware layers' => sub {

        my $res = $cb->(GET "http://localhost/");
        is $res->code, 404, 'Response HTTP status';
        is $res->content_type, 'text/plain', 'Response Content-Type';
        is $res->content, 'not found', 'Response body';

    };

    subtest 'The Static middleware layer' => sub {

        subtest 'Existing image' => sub {
            my $res = $cb->(GET "http://localhost/images/100x100.png");
            is $res->code, 200, 'Response HTTP status';
            is $res->content_type, 'image/png', 'Response Content-Type';
        };

        subtest 'Non-existing image' => sub {
            my $res = $cb->(GET "http://localhost/images/nonexisting.png");
            is $res->code, 404, 'Response HTTP status';
        };

    };

};

done_testing;

