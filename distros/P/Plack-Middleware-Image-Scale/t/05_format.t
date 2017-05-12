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
    enable 'Static', path => qr{^/images/}, root => 't', pass_through => 1;
    sub { [
        404,
        [ 'Content-Type' => 'text/plain', 'Content-Length' => 8 ],
        [ 'not found' ]
    ] };
};

test_psgi $handler, sub {
    my $cb = shift;

    subtest 'Not found case' => sub {
        my $res = $cb->(GET "http://localhost/images/no_100x100.png");
        is $res->code, 404, "no_100x100.png code 404";
        is $res->content, 'not found', "no_100x100.png content 'not found'";
    };

    subtest 'Formats' => sub {

        my @formats = (
            [ 'jpg to png',  '75x75_x.png',  'image/png' ],
            [ 'jpg to jpg',  '75x75_x.jpg',  'image/jpeg' ],
            [ 'jpg to jpeg', '75x75_x.jpeg', 'image/jpeg' ],

            [ 'png to png',  '100x100_x.png',  'image/png' ],
            [ 'png to jpg',  '100x100_x.jpg',  'image/jpeg' ],
            [ 'png to jpeg', '100x100_x.jpeg', 'image/jpeg' ],
        );

        for my $row ( @formats ) {
            my ($name, $filename, $ct) = @$row;
            subtest $name => sub {
                my $res = $cb->(GET "http://localhost/images/$filename");
                is $res->code, 200, 'Response HTTP status';
                is $res->content_type, $ct, 'Response Content-Type';
            };
        }

    };
};

done_testing;

