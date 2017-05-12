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

my $fav_app = Plack::Middleware::Favicon->new(
    src_image_file  => 'share/src_favicon.png',
    custom_favicons => [
        {
            path => qr!^/favicon\.ico!, size => [32, 32],
            type => 'png', mime_type => 'image/png',
        },
    ],
)->to_app;

test_psgi $fav_app, sub {
    my $cb = shift;
    my $res = $cb->(GET '/favicon.ico');

    is $res->code, 200;
    is $res->content_type, 'image/png';
    my $img = Imager->new(data => $res->content);
    is $img->getwidth,  32;
    is $img->getheight, 32;
};

done_testing;
