use strict;
use warnings;
use lib 't/lib';
use Test::Invocation::Arguments;
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
    enable 'Image::Scale', memory_limit => undef;
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

    subtest 'Basic size arguments' => sub {

        my @sizetests = (
            [ '100x100_x.png', [{ width => 100, height => 100 }], undef ],
            [ '100x100_200x.png', [{ width => 200 }], undef ],
        );

        for my $row ( @sizetests ) {
            my ($filename, $resize, $crop) = @$row;
            subtest $filename => sub {
                my $resize_calls = Test::Invocation::Arguments->new(class => 'Image::Scale', method => 'resize');
                my $crop_calls = Test::Invocation::Arguments->new(class => 'Imager', method => 'crop');

                my $res = $cb->(GET "http://localhost/images/$filename");
                is $res->code, 200, 'Response HTTP status';

                is_deeply $resize_calls->pop, $resize, 'resize args';
                is $resize_calls->count, 0, 'only one resize call';

                is_deeply $crop_calls->pop, $crop, 'crop args';
                is $crop_calls->count, 0, 'only one crop call';
            };
        }

    };
};

done_testing;

