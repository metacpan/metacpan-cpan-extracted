# vim: set expandtab ts=4 sw=4 nowrap ft=perl ff=unix :
use strict;
use warnings;
use utf8;
use Test::More;

use Plack::Middleware::Image::Dummy;

subtest 'basic parse_params test' => sub {
    my $parsed_params = Plack::Middleware::Image::Dummy::parse_params(
        '123x456.png',
        Hash::MultiValue->new()
    );
    is_deeply(
        $parsed_params,
        +{
            text       => '123x456',
            width      => 123,
            height     => 456,
            ext        => 'png',
            text_color => $Plack::Middleware::Image::Dummy::DEFAULT_TEXT_COLOR,
            background_color =>
              $Plack::Middleware::Image::Dummy::DEFAULT_BACKGROUND_COLOR,
            min_font_size =>
              $Plack::Middleware::Image::Dummy::DEFAULT_MIN_FONT_SIZE,
        }
    );
};

subtest 'basic parse_params test with query' => sub {
    my $orig_params = Hash::MultiValue->new(
        text    => 'kikiさんぺろぺろ(Japanese Text)',
        color   => '#abcdef',
        bgcolor => '#012345',
        minsize => '12',
    );

    my $parsed_params = Plack::Middleware::Image::Dummy::parse_params(
        '123x456.png',
        $orig_params
    );
    is_deeply(
        $parsed_params,
        +{
            text       => $orig_params->{text},
            width      => 123,
            height     => 456,
            ext        => 'png',
            text_color => Plack::Middleware::Image::Dummy::parse_color(
                $orig_params->{color}
            ),
            background_color => Plack::Middleware::Image::Dummy::parse_color(
                $orig_params->{bgcolor}
            ),
            min_font_size => $orig_params->{minsize},
        }
    );
};

done_testing;
