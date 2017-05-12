# vim: set expandtab ts=4 sw=4 nowrap ft=perl ff=unix :
package Plack::Middleware::Image::Dummy;
use strict;
use warnings;
use 5.008005;
our $VERSION = '0.05';

use parent qw/Plack::Middleware/;

use Imager;
use Plack::Request;
use Plack::MIME;
use Plack::Util;
use Plack::Util::Accessor
  qw/map_path font_path param_filter max_width max_height/;

our $DEFAULT_TEXT_COLOR       = [ 0,    0,    0 ];
our $DEFAULT_BACKGROUND_COLOR = [ 0xcc, 0xcc, 0xcc ];
our $DEFAULT_MIN_FONT_SIZE    = 18;
our $DEFAULT_MAX_WIDTH        = 2048;
our $DEFAULT_MAX_HEIGHT       = 2048;

sub prepare_app {
    my $self = shift;

    my @err_msgs;

    push @err_msgs, 'Please specify map_path.'  unless $self->map_path;
    push @err_msgs, 'Please specify font_path.' unless $self->font_path;
    $self->max_width($DEFAULT_MAX_WIDTH)   unless $self->max_width;
    $self->max_height($DEFAULT_MAX_HEIGHT) unless $self->max_height;

    die join(' ', @err_msgs) if scalar(@err_msgs) > 0;
}

sub call {
    my ($self, $env) = @_;

    my $path_info = match_path($env->{PATH_INFO}, $self->map_path);

    if ($path_info) {
        my $query;
        if ($env->{'QUERY_STRING'}) {
            my $req = Plack::Request->new($env);
            $query = $req->query_parameters;
        }
        my $params = parse_params($path_info, $query);
        if ($params) {
            $params = $self->param_filter->($params) if $self->param_filter;

            if ($params) {
                return return_error(
                    500,
                    "Width is too big. Max is $self->max_width"
                ) if $self->max_width < $params->{width};

                return return_error(
                    500,
                    "Height is too big. Max is $self->max_height"
                ) if $self->max_height < $params->{height};

                return create_image($params, $self->font_path) if $params;
            }
        }
        return_error(404, 'Not found.');
    } else {
        $self->app->($env);
    }
} ## end sub call

sub match_path {
    my ($given_path, $config_path) = @_;

    my $ref_config_path = ref $config_path;

    if ($ref_config_path eq 'Regexp') {
        $given_path =~ s/$config_path//g;
        $given_path;
    } elsif (defined $config_path) {
        my $match_length = length($config_path);
        if (substr($given_path, 0, $match_length) eq $config_path) {
            substr($given_path, $match_length);
        } else {
            undef;
        }
    } else {
        undef;
    }
}

sub create_image {
    my ($params, $font_path) = @_;

    my $img = Imager->new(
        xsize => $params->{width}, ysize => $params->{height},
        type  => 'paletted'
    );

    # draw background
    {
        my $background_color =
          Imager::Color->new(@{ $params->{background_color} });
        $img->box(
            color  => $background_color,
            xmin   => 0, ymin => 0,
            xmax   => $params->{width}, ymax => $params->{height},
            filled => 1
        );
    }

    # draw text
    {
        my $text_color = Imager::Color->new(@{ $params->{text_color} });
        my $font       = Imager::Font->new(file => $font_path);
        my $font_size  = determine_font_size(
            $font,             $params->{text},  $params->{width},
            $params->{height}, $params->{width}, $params->{min_font_size}
        );
        $img->align_string(
            size   => $font_size,
            x      => $params->{width} / 2, y => $params->{height} / 2,
            halign => 'center', valign => 'center',
            font   => $font, string => $params->{text}, utf8 => 1, aa => 1,
            color  => $text_color
        );
    }

    return_image($img, $params->{ext});
} ## end sub create_image

sub parse_params {
    my ($path_info, $query) = @_;

    # ex.) 600x480.jpg
    my $path_regex = qr{\A(\d+)x(\d+)\.(jpe?g|png|gif)\z};

    my ($width, $height, $ext) = ($path_info =~ $path_regex);

    return undef unless $ext;

    $ext = 'jpeg' if $ext eq 'jpg';

    my $text             = $width . 'x' . $height;
    my $text_color       = $DEFAULT_TEXT_COLOR;
    my $background_color = $DEFAULT_BACKGROUND_COLOR;
    my $min_font_size    = $DEFAULT_MIN_FONT_SIZE;

    if ($query) {
        $text = $query->{'text'} if $query->{'text'};
        $text_color = parse_color($query->{'color'}) if $query->{'color'};
        $background_color = parse_color($query->{'bgcolor'})
          if $query->{'bgcolor'};
        $min_font_size = $query->{'minsize'} if $query->{'minsize'};
    }

    +{
        text             => $text,
        width            => $width,
        height           => $height,
        ext              => $ext,
        text_color       => $text_color,
        background_color => $background_color,
        min_font_size    => $min_font_size,
    };
} ## end sub parse_params

sub determine_font_size {
    my ($font, $text, $width, $height, $default_size, $min_size) = @_;

    my $size     = $default_size;
    my $max_size = $default_size;

    DETERMINE: while (1) {
        my $bounding_box = $font->bounding_box(string => $text, size => $size);
        my $width_ratio = $bounding_box->display_width() / $width;

        if (($size - $min_size) < 1) {
            $size = $min_size;
            last DETERMINE;
        } elsif ($width_ratio > 1) {
            $max_size = $size;
        } elsif ($width_ratio > 0.9) {
            last DETERMINE;
        } else {
            $min_size = $size;
        }
        $size = ($max_size + $min_size) / 2;
        my $l = $bounding_box->display_width();
    }

    $size;
}

sub return_image {
    my ($img, $type) = @_;

    my $binary;
    $img->write(data => \$binary, type => $type) or die $img->errstr;

    my $content_type = Plack::MIME->mime_type(".$type");
    return [
        200,
        [
            'Content-Type' => $content_type, 'Content-Length' => length($binary)
        ],
        [$binary]
    ];
}

sub return_error {
    my ($response_code, $body) = @_;
    return [
        $response_code,
        [ 'Content-Type' => 'text/plain', 'Content-Length' => length($body) ],
        [$body]
    ];
}

sub parse_color {
    my ($color_str) = @_;

    if ($color_str =~ /^([0-9a-fA-F]{6})$/) {
        my $rgb = hex($1);
        my $b   = $rgb & 0xff; $rgb >>= 8;
        my $g   = $rgb & 0xff; $rgb >>= 8;
        my $r   = $rgb;
        return [ $r, $g, $b ];
    }
}

1;
__END__

=encoding utf8

=head1 NAME

Plack::Middleware::Image::Dummy - Dummy image responser for Plack

=head1 SYNOPSIS

    ## example.psgi

    builder {
        # basic
        enable 'Image::Dummy', map_path => '/', font_path => './font/MTLmr3m.ttf';

        # map path with regex
        enable 'Image::Dummy', map_path => qr/^\//, font_path => './font/MTLmr3m.ttf';

        # change max_width and max_height
        enable 'Image::Dummy', map_path => '/', font_path => './font/MTLmr3m.ttf',
          max_width => 100, max_height => 200;

        # with param_filter
        enable 'Image::Dummy', map_path => '/', font_path => './font/MTLmr3m.ttf', param_filter => sub {
            my $params = shift;
            if ($ENV{PLACK_ENV} eq 'production') {
                print STDERR "Do not show under production environment.\n";
                undef;
            } else {
                $params->{text} .= ':D';
                $params;
            }
        };

        $app;
    };

=head1 DESCRIPTION

Plack::Middleware::Image::Dummy is dummy image responser for Plack like L<http://dummyimage.com/>.

=head1 CONFIGURATION

=head2 map_path

URI path mapped to this module.

=head2 font_path

Font path.

=head2 max_width

Max width of image. Default is 2048.

=head2 max_height

Max height of image. Default is 2048.

=head2 param_filter

A code reference. The code called with one HashRef contains parsed parameters.
Evaluated value is used in image creation.

=head1 URI

You can get a image detailed in URI like below.

    http://host:port#{map_path}/#{width}x#{height}.#{ext}?param=value&...

=head2 path

You can specify width, height and file type (ex. png, gif, jpg) in path of URI.

=head2 text

You can specify text written in the center of the image. Default is #{width}x#{height}.

=head2 color

You can specify text color with 'RRGGBB'. ex.) ff0000 is red.

=head2 bgcolor

You can specify background color with 'RRGGBB'. ex.) 00ff00 is green.

=head2 minsize

You can specify minimum size of font.

=head1 AUTHOR

Tasuku SUENAGA a.k.a. gunyarakun E<lt>tasuku-s-cpan ATAT titech.acE<gt>

=head1 REPOSITORY

L<https://github.com/gunyarakun/p5-Plack-Middleware-Image-Dummy>

    git clone git://github.com/gunyarakun/p5-Plack-Middleware-Image-Dummy.git

=head1 SEE ALSO

L<Imager>

L<Imager::File::GIF>

=head1 LICENSE

Files in 'font' directory are licensed under the Apache License 2.0.

Copyright (C) Tasuku SUENAGA a.k.a. gunyarakun

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
=cut
