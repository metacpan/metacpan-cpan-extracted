package Plack::App::DummyBox;
use strict;
use warnings;
use Carp qw/croak/;
use parent qw/Plack::Component/;
use Imager;
use Image::Empty;
use HTTP::Status qw//;
use HTTP::Date qw//;
use Plack::Request;
use Plack::Util qw//;
use Plack::Util::Accessor qw/
    dot_gif
    dot_png
    font
    text
    filter
    cache
    cache_key
    max_width
    max_height
    stderr
/;

our $VERSION = '0.041';

sub prepare_app {
    my $self = shift;

    $self->max_width(5000) unless $self->max_width;
    $self->max_height(5000) unless $self->max_height;

    $self->dot_gif(Image::Empty->gif);
    $self->dot_png(Image::Empty->png);

    if ($self->font) {
        my $font = Imager::Font->new(
            file => $self->font->{file},
            type => $self->font->{type},
            size => $self->font->{size}   || 15,
            color => $self->font->{color} || 'darkgray',
        ) or croak(Imager->errstr);
        $self->font($font);
    }

    return $self;
}

sub call {
    my ($self, $env) = @_;

    my $req  = Plack::Request->new($env);

    my $w = int($req->param('width') || $req->param('w') || 1);
    return $self->return_status(400) if $w > $self->max_width;
    my $h = int($req->param('height') || $req->param('h') || 1);
    return $self->return_status(400) if $h > $self->max_height;
    my $ext = $req->param('ext') || 'gif';
    return $self->return_status(400) if $ext !~ m!^(?:gif|png)$!;

    my $ext_obj = ($ext eq 'gif') ? $self->dot_gif : $self->dot_png;

    if ($w == 1 && $h == 1) {
        #----- dot image
        my $disposition = $ext_obj->disposition. '; filename="'
                            . $ext_obj->filename. '"';
        return [
            200,
            [
                'Content-Type'   => $ext_obj->type,
                'Content-Length' => $ext_obj->length,
                'Content-Disposition' => $disposition,
                'Last-Modified'  => HTTP::Date::time2str(time),
            ],
            [$ext_obj->content]
        ];
    }
    else {
        #----- box
        my $fill   = $req->param('fill')   || 'white';
        my $border = $req->param('border') || 'gray';
        my $line   = int($req->param('line') || 1); $line++;
        return $self->return_status(400) if $line > $w && $line > $h;

        if ($self->cache) {
            $self->cache_key(
                join ':',
                    $w, $h, $ext, $fill, $border, $line
            );
            if ( my $cache = $self->cache->get($self->cache_key) ) {
                return [ 200, @{$cache} ];
            }
        }

        my $img = Imager->new(xsize => $w, ysize => $h);
        $img->box(
            filled => 1,
            color  => $border
        );
        $img->box(
            xmin => $line-1,  ymin => $line-1,
            xmax => $w-$line, ymax => $h-$line,
            filled => 1,
            color => $fill,
        );

        if ($self->font) {
            $img->string(
                font => $self->font,
                x => 5,
                y => $self->font->{size}+5,
                string => "$w x $h",
                aa => 1,
            ) or return $self->return_status(500, Imager->errstr);

            if ($self->text) {
                $img->string(
                    font => $self->font,
                    x => 5,
                    y => $self->font->{size}*2+5+5,
                    string => $self->text,
                    aa => 1,
                ) or return $self->return_status(500, Imager->errstr);
            }
        }

        if (ref($self->filter) eq 'CODE') {
            $self->filter->($self, $img);
        }

        my $content = '';
        $img->write(data => \$content , type => $ext);
        my $disposition = $ext_obj->disposition. '; filename="'
                            . "${w}x$h\.$ext". '"';

        my $response = [
            [
                'Content-Type'   => $ext_obj->type,
                'Content-Length' => length $content,
                'Content-Disposition' => $disposition,
                'Last-Modified'  => HTTP::Date::time2str(time),
            ],
            [$content]
        ];

        if ($self->cache) {
            $self->cache->set($self->cache_key => $response);
        }
        return [ 200, @{$response} ];
    }
}

sub return_status {
    my $self        = shift;
    my $status_code = shift || 500;
    my $err         = shift || '';

    if ($self->stderr) {
        print STDERR "$err\n";
    }

    my $msg = HTTP::Status::status_message($status_code);

    return [
        $status_code,
        [
            'Content-Type' => 'text/plain',
            'Content-Length' => length $msg
        ],
        [$msg]
    ];
}

1;

__END__

=head1 NAME

Plack::App::DummyBox - generate dummy box image for web development


=head1 SYNOPSIS

    # app.psgi
    use Plack::App::DummyBox;
    my $dummy_box_app = Plack::App::DummyBox->new->to_app;

    # then map it
    use Plack::Builder;
    builder {
        mount "/dummy_box" => $dummy_box_app;
    };


=head1 DESCRIPTION

Plack::App::DummyBox generates dummy box images. You can easily get dot images(1x1 git/png) or free size box images. This module may help your designers to make mock of service.


=head1 PARAMETERS

You can set query parameters every request.

=over 4

=item width

box width size(pixel). B<w> is alias as width: default 1

=item height

box height size(pixel). B<h> is alias as height: default 1

=item ext

extension of image: C<gif> or C<png>, default gif

=item fill

color of box: default C<white>

=item border

border color of box: default C<gray>

=item line

size of border line(pixel): default 1

=back


=head1 CONSTRACTOR OPTIONS

    my $dummy_box_app = Plack::App::DummyBox->new(
        max_width  => 640,
        max_height => 480,
        font => +{
            file  => "/path/to/font_file.ttf",
            type  => "ft2",
            size  => 15,    # option
            color => 'red', # option
        },
        text   => "foo",
        filter => sub {
            my ($self, $img) = @_;
            # .. do something ..
        },
        cache => Cache::File->new(cache_root => '/tmp/cache'),
        stderr => 1,
    )->to_app;

=over 4

=item max_width, max_height

if the size was over, response HTTP STATUS: 400.

=item font

If you want to see image size as text on the image, you should set C<font> option. see L<Imager::Font>

=item text

add a text in the image. C<text> option also requires C<font> option. Note that text string should be decoded utf8 text when it included not ascii strings.

=item filter

filter should code reference. This method receives the $self and Imager object.

=item cache

If you want to cache responses between requests, provide the C<cache> parameter with an object supporting the Cache API(e.g. Cache::File). Specifically, an object that supports $cache->get($key) and $cache->set($key, $value, $expires).

=item stderr

print error message to STDERR when some error was happen.

=back


=head1 METHODS

=over 4

=item prepare_app

=item call

=item return_status($status_code)

return HTTP status and message.

=back


=head1 REPOSITORY

Plack::App::DummyBox is hosted on github
<http://github.com/bayashi/Plack-App-DummyBox>


=head1 AUTHOR

Dai Okabayashi E<lt>bayashi@cpan.orgE<gt>


=head1 SEE ALSO

L<Plack::Component>, L<Image::Empty>, L<Imager>


=head1 LICENSE

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.

=cut
