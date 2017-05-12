# vim: set expandtab ts=4 sw=4 nowrap ft=perl ff=unix :
use strict;
use warnings;
use utf8;
use Test::More;

use Plack::Middleware::Image::Dummy;

subtest 'basic parse_color test' => sub {
    my $parsed_color = Plack::Middleware::Image::Dummy::parse_color('123456');
    is_deeply($parsed_color, [ 0x12, 0x34, 0x56 ]);
};

done_testing;
