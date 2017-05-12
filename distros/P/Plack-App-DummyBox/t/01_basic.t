use strict;
use warnings;
use Test::More 0.88;
use Plack::Test;
use HTTP::Request::Common;
use MIME::Base64;
use Imager;

use Plack::App::DummyBox;

note('methods');
{
    can_ok 'Plack::App::DummyBox', qw/
        prepare_app
        call
        return_status
    /;
}

my $app = Plack::App::DummyBox->new->to_app;

for my $type (qw/gif png/) {
    diag("The Imager module in this system does NOT support: $type")
        unless $Imager::formats{$type};
}

note('1x1 images');
{
    test_psgi $app, sub {
        my $cb = shift;

        my $res = $cb->(GET '/');

        is $res->code, 200, 'response status 200';
        is $res->content_type, 'image/gif', 'default content_type';
        like $res->content, qr/^GIF.+/, 'gif image';
        is(
            $res->content,
            MIME::Base64::decode_base64('R0lGODlhAQABAIAAAP///wAAACH5BAEAAAAALAAAAAABAAEAAAICRAEAOw=='),
            'gif image content'
        );
    };
}

{
    test_psgi $app, sub {
        my $cb = shift;

        my $res = $cb->(GET '/?ext=png');

        is $res->code, 200, 'response status 200';
        is $res->content_type, 'image/png', 'png content_type';
        like $res->content, qr/PNG.+/, 'png image';
        is(
            $res->content,
            MIME::Base64::decode_base64('iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAACklEQVR4nGMAAQAABQABDQottAAAAABJRU5ErkJggg=='),
            'png image content'
        );
    };
}

note('Imager images');
{
    my $img = Imager->new;
    test_psgi $app, sub {
        my $cb = shift;

        # gif(default)
        my $res = $cb->(GET '/?w=99&h=99');

        is $res->code, 200, 'response status 200';
        is $res->content_type, 'image/gif', 'default content_type';

        SKIP: {
            skip 'gif is not supported', 3 unless $Imager::formats{gif};

            ok $res->content_length > 0, 'gif image content';
            like $res->content, qr/^GIF.+/, 'gif image';

            $img->read(data => $res->content);
            is $img->colorcount, 2, 'color count';
        }

        # png
        my $res_png = $cb->(GET '/?w=99&h=99&ext=png');

        is $res_png->code, 200, 'response status 200';
        is $res_png->content_type, 'image/png', 'png content_type';

        SKIP: {
            skip 'png is not supported', 2 unless $Imager::formats{png};

            ok $res_png->content_length > 0, 'png image content';
            like $res_png->content, qr/^.+PNG.+/, 'png image';
        }
    };
}

done_testing;
