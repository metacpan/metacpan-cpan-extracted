use strict;
use warnings;
use Test::More;
use Plack::Test;
use HTTP::Request::Common;
use Imager;

use Plack::Middleware::Favicon;

unless ( grep { $_ =~ m!png! } Imager->read_types ) {
    plan skip_all => "You must install 'libpng'";
}
unless ( grep { $_ =~ m!ico! } Imager->write_types ) {
    plan skip_all => "You must install 'libico'";
}

my $fav = Plack::Middleware::Favicon->new(
    src_image_file => 'share/src_favicon.png',
);

isa_ok $fav, 'Plack::Middleware::Favicon';

my $fav_app = $fav->to_app;

is ref($fav_app), 'CODE';

test_psgi $fav_app, sub {
    my $cb = shift;
    my $res = $cb->(GET '/favicon.ico', User_Agent => 'MSIE 6.0');

    is $res->code, 200;
    is $res->content_type, 'image/x-icon';
    my $img = Imager->new(data => $res->content);
    is $img->getwidth,  16;
    is $img->getheight, 16;
};

test_psgi $fav_app, sub {
    my $cb = shift;
    my $res = $cb->(GET '/favicon.ico');

    is $res->code, 200;
    is $res->content_type, 'image/x-icon';
    my $img = Imager->new(data => $res->content);
    like $res->content, qr/PNG/;
    is $img->getwidth,  16;
    is $img->getheight, 16;
};

test_psgi $fav_app, sub {
    my $cb = shift;
    my $res = $cb->(GET '/mstile-310x150.png');

    is $res->code, 200;
    is $res->content_type, 'image/png';
    my $img = Imager->new(data => $res->content);
    is $img->getwidth,  310;
    is $img->getheight, 150;
};

done_testing;
