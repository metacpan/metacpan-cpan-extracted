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

    subtest 'Basic size tests' => sub {

        my @sizetests = (
            [ '100x100_x.png',                 200, 100, 100 ],
            [ '100x100_200x.png',              200, 200, 200 ],
            [ '100x100_50x.png',               200,  50,  50 ],
            [ '100x100_x200.png',              200, 200, 200 ],
            [ '100x100_x50.png',               200,  50,  50 ],

            [ '100x100_x-z20.png',             200, 100, 100 ],
            [ '100x100_200x-z20.png',          200, 200, 240 ],
            [ '100x100_50x-z20.png',           200,  50,  60 ],
            [ '100x100_x200-z20.png',          200, 240, 200 ],
            [ '100x100_x50-z20.png',           200,  60,  50 ],

            [ '100x100_x-crop.png',            200, 100, 100 ],
            [ '100x100_200x-crop.png',         200, 200, 200 ],
            [ '100x100_50x-crop.png',          200,  50,  50 ],
            [ '100x100_x200-crop.png',         200, 200, 200 ],
            [ '100x100_x50-crop.png',          200,  50,  50 ],

            [ '100x100_200x100.png',           200, 200, 100 ],
            [ '100x100_200x100-fill.png',      200, 200, 100 ],
            [ '100x100_200x100-crop.png',      200, 200, 100 ],
            [ '100x100_200x100-crop-fill.png', 200, 200, 100 ],
            [ '100x100_200x100-crop-z0.png',   200, 200, 100 ],
            [ '100x100_200x100-crop-z20.png',  200, 200, 100 ],
            [ '100x100_200x100-crop-z100.png', 200, 200, 100 ],
            [ '100x100_40x80-fit.png',         200,  40,  40 ],
            [ '100x100_80x40-fit.png',         200,  40,  40 ],

            [ '100x100_200x100-fill0x00ff00.png', 200, 200, 100 ],
        );

        for my $row ( @sizetests ) {
            my ($filename, $status, $width, $height) = @$row;
            subtest $filename => sub {
                my $res = $cb->(GET "http://localhost/images/$filename");
                my $img = Imager->new( data => $res->content );
                is $res->code, $status, 'Response HTTP status';
                is $img->getwidth, $width, 'Response image width';
                is $img->getheight, $height, 'Response image height';
            };
        }

    };
};

done_testing;

