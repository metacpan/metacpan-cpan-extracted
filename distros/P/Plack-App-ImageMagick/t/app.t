
use strict;
use warnings;

use Plack::Test;
use Plack::Builder;
use HTTP::Request::Common;

use Test::More tests => 23;
use Test::NoWarnings;

use Plack::App::ImageMagick;

my $app = builder {
    mount "/images/handler_grayscale/" => Plack::App::ImageMagick->new(
        handler => sub {
            my ($app, $env, $img) = @_;

            my $root = "t/images";

            my $IMG = $root . $env->{PATH_INFO};
            $img->Read( $IMG );

            $img->Quantize( colorspace => 'gray' );
            $img->Scale( geometry => '200x120' );
            $img->Set( quality => 30 );

            return $img;
        },
    );
    mount "/images/apply_grayscale/" => Plack::App::ImageMagick->new(
        root => "t/images",
        apply => [
            Quantize => { colorspace => 'gray' },
            Scale => { geometry => "200x120" },
            Set => { quality => 30 },
        ],
    );
    mount "/images/with_query/" => Plack::App::ImageMagick->new(
        root => "t/images",
        apply => [
            Set => { quality => 30 },
            Colorize => { opacity => '%{opacity}%', fill => '%{color}'},
            '%{method}' => { geometry => '200x120' }
        ],
        with_query => 1,
    );
    mount "/images/colors/" => Plack::App::ImageMagick->new(
        root => "t/images",
        apply => [
            Opaque => {
                color => 'blue',
                fill => 'red',
            },
            Opaque => {
                color => 'black',
                fill => 'green',
            },
            Opaque => {
                color => 'yellow',
                fill => 'orange',
            },
        ],
    );
    mount "/images/fx/" => Plack::App::ImageMagick->new(
        cache_dir => "t/images/cache",
        root => "t/images",
        apply => [
            Clone => 1,
            Fx => {
                expression => 'u.b',
                channel => 'red',
            },
            Fx => {
                expression => 'u[1].r',
                channel => 'blue',
            },
        ],
    );
    mount "/images/pix/" => Plack::App::ImageMagick->new(
        cache_dir => "t/images/cache",
        apply => [
            Set => { size => "1x1" },
            ReadImage => [
                'xc:%{color}',
            ],
            Set => { magick => "png" },
        ],
        with_query => 1,
    );
    mount "/images/text/" => Plack::App::ImageMagick->new(
        cache_dir => "t/images/cache",
        apply => [
            Set => { size => "100x20" },
            ReadImage => [
                'xc:%{bgcolor:-white}',
            ],
            Set => { magick => "png" },
            Annotate => {
                text => '%{text:-[^ Hello! ^]}',
                fill => '%{color:-black}',
                pointsize => 16,
                gravity => 'Center',
            },
        ],
        with_query => 1,
    );
    mount "/images/prepost/" => Plack::App::ImageMagick->new(
        cache_dir => "t/images/cache",
        pre_process => sub {
            my ($app, $env, $img) = @_;

            $img->Set( size => "40x40" );

            return $img;
        },
        apply => [
            ReadImage => [
                'xc:white',
            ],
            Set => { magick => "png" },
            Annotate => {
                text => 'abc',
                fill => 'red',
                pointsize => 16,
                gravity => 'Center',
            }
        ],
        post_process => sub {
            my ($app, $env, $img) = @_;

            $img->Flop();

            return $img;
        },
    );

    mount "/images/unknownmethod/" => Plack::App::ImageMagick->new(
        apply => [
            '%{method}' => { geometry => '200x120' }
        ],
        with_query => 1,
    );
    mount "/images/image_not_found/" => Plack::App::ImageMagick->new(
        root => "t/images",
        apply => [
            Set => { quality => 30 },
        ],
    );
    mount "/images/methodfails/" => Plack::App::ImageMagick->new(
        apply => [
            Read => [ "t/non/existent/image.png" ],
        ],
    );



    mount "/" => sub {
        return [
            200, [ 'Content-Type' => 'text/html' ],
            [
                q{
<html>
    <body>
        <a href="http://search.cpan.org/dist/Plack-App-ImageMagick/">
            Plack::App::ImageMagick
        </a>
    </body>
</html>
                }
            ]
        ];
    };
};

eval {
    Plack::App::ImageMagick->new();
};
like $@, qr/handler or apply is required/, "handler or apply is required";

eval {
    Plack::App::ImageMagick->new(
        handler => sub {},
        apply => [ ReadImage => [ 'xc:white' ] ],
    );
};
like $@, qr/handler and apply are mutually exclusive/,
    "handler and apply are mutually exclusive";

eval {
    Plack::App::ImageMagick->new(
        apply => {},
    );
};
like $@, qr/apply should be non-empty array reference/,
    "apply should be non-empty array reference";

eval {
    Plack::App::ImageMagick->new(
        apply => [],
    );
};
like $@, qr/apply should be non-empty array reference/,
    "apply should be non-empty array reference";

eval {
    Plack::App::ImageMagick->new(
        handler => sub {},
        with_query => [],
    );
};
like $@, qr/with_query requires apply/,
    "with_query requires apply";

eval {
    Plack::App::ImageMagick->new(
        pre_process => sub {},
        handler => sub {},
    );
};
like $@, qr/pre\/post processing methods are allowed only for apply option/,
    "pre/post processing methods are allowed only for apply option";

eval {
    Plack::App::ImageMagick->new(
        post_process => sub {},
        handler => sub {},
    );
};
like $@, qr/pre\/post processing methods are allowed only for apply option/,
    "pre/post processing methods are allowed only for apply option";

eval {
    Plack::App::ImageMagick->new(
        pre_process => sub {},
        post_process => sub {},
        handler => sub {},
    );
};
like $@, qr/pre\/post processing methods are allowed only for apply option/,
    "pre/post processing methods are allowed only for apply option";



test_psgi $app, sub {
    my $cb = shift;

    # 1
    my $res_handler_grayscale_thumb = $cb->(
        GET '/images/handler_grayscale/Camelia.png'
    );

    my $ref_handler_thumb = Image::Magick->new();
    $ref_handler_thumb->Read( "t/images/Camelia-handler-thumb.png" );

    my $out_handler_thumb = Image::Magick->new( magick => 'png' );
    $out_handler_thumb->BlobToImage( $res_handler_grayscale_thumb->content );

    ok ! $ref_handler_thumb->Difference( image => $out_handler_thumb ),
        "thumbnail via handler created";

    # 2
    my $res_apply_grayscale_thumb = $cb->(
        GET '/images/apply_grayscale/Camelia.png'
    );

    my $ref_apply_thumb = Image::Magick->new();
    $ref_apply_thumb->Read( "t/images/Camelia-apply-thumb.png" );

    my $out_apply_thumb = Image::Magick->new( magick => 'png' );
    $out_apply_thumb->BlobToImage( $res_apply_grayscale_thumb->content );

    ok ! $ref_apply_thumb->Difference( image => $out_apply_thumb ),
        "thumbnail via apply created";

    # 3
    my $res_with_query = $cb->(
        GET '/images/with_query/Camelia.png?method=Scale&opacity=50&color=red'
    );

    my $ref_with_query = Image::Magick->new();
    $ref_with_query->Read( "t/images/Camelia-with_query.png" );

    my $out_with_query = Image::Magick->new( magick => 'png' );
    $out_with_query->BlobToImage( $res_with_query->content );

    ok ! $ref_with_query->Difference( image => $out_with_query ),
        "thumbnail via with_query created";

    # 4
    my $res_colors = $cb->(
        GET '/images/colors/Camelia.png'
    );

    my $ref_colors = Image::Magick->new();
    $ref_colors->Read( "t/images/Camelia-colors.png" );

    my $out_colors = Image::Magick->new( magick => 'png' );
    $out_colors->BlobToImage( $res_colors->content );

    ok ! $ref_colors->Difference( image => $out_colors ),
        "colors changed via apply";

    # 5
    my $res_fx = $cb->(
        GET '/images/fx/photo.jpg'
    );

    my $ref_fx = Image::Magick->new();
    $ref_fx->Read( "t/images/photo-fx.jpg" );

    my $out_fx = Image::Magick->new( magick => 'jpg' );
    $out_fx->BlobToImage( $res_fx->content );

    ok ! $ref_fx->Difference( image => $out_fx ),
        "Fx via apply";

    unlink("t/images/cache/48c184fdd2999a7ae824071bb128f7c8");

    # 6
    my $res_pix = $cb->(
        GET '/images/pix/1x1.png?color=red&foo='
    );

    my $ref_pix = Image::Magick->new();
    $ref_pix->Read( "t/images/1x1-red.png" );

    my $out_pix = Image::Magick->new( magick => 'png' );
    $out_pix->BlobToImage( $res_pix->content );

    ok ! $ref_pix->Difference( image => $out_pix ),
        "image via with_query created";

    unlink("t/images/cache/f9a434bb29320e1703a62a14ba378d12");

    # 7
    my $res_text = $cb->(
        GET '/images/text/message.png?text=Hi there'
    );

    my $ref_text = Image::Magick->new();
    $ref_text->Read( "t/images/text.png" );

    my $out_text = Image::Magick->new( magick => 'png' );
    $out_text->BlobToImage( $res_text->content );

    ok ! $ref_text->Difference( image => $out_text ),
        "annotation via with_query created";

    # 8
    my $res_prepost = $cb->(
        GET '/images/prepost/mirror.png'
    );

    my $ref_prepost = Image::Magick->new();
    $ref_prepost->Read( "t/images/prepost.png" );

    my $out_prepost = Image::Magick->new( magick => 'png' );
    $out_prepost->BlobToImage( $res_prepost->content );

    ok ! $ref_prepost->Difference( image => $out_prepost ),
        "pre/post processing executed";

    # 9
    {
        local $SIG{__WARN__} = sub {
            like shift @_, qr/^Undefined method at index: 0/,
                "expected warning thrown";
        };
        my $res_unknownmethod = $cb->(
            GET '/images/unknownmethod/Camelia.png'
        );
        is $res_unknownmethod->code, 500, "invalid params throw 500";
    }

    # 10
    {
        local $SIG{__WARN__} = sub {
            like shift @_, qr/^Read\([^\)]+\) failed:/,
                "expected warning thrown";
        };
        my $res_image_not_found = $cb->(
            GET '/images/image_not_found/camel.png'
        );
        is $res_image_not_found->code, 404, "failed Read throws 404";
    }

    # 11
    {
        local $SIG{__WARN__} = sub {
            like shift @_, qr/^Read\([^\)]+\) failed:/,
                "expected warning thrown";
        };
        my $res_methodfails = $cb->(
            GET '/images/methodfails/image.png'
        );
        is $res_methodfails->code, 500, "failed method throws 500";
    }

}
