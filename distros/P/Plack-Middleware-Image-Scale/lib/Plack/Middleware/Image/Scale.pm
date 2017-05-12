use strict;
package Plack::Middleware::Image::Scale;
our $AUTHORITY = 'cpan:PNU';
# ABSTRACT: Resize jpeg and png images on the fly

use Moose;
use Class::Load;
use Plack::Util;
use Plack::MIME;
use Try::Tiny;
use Image::Scale;
use List::Util qw( min max );
use Carp;

extends 'Plack::Middleware';

our $VERSION = '0.011'; # VERSION


has path => (
    is => 'rw', lazy => 1, isa => 'RegexpRef|CodeRef|Str|Undef',
    default => undef
);


has match => (
    is => 'rw', lazy => 1, isa => 'RegexpRef|CodeRef',
    default => sub { qr{^(.+?)(?:_([^_]+?))?(?:\.(jpe?g|png|image))$} }
);


has size => (
    is => 'rw', lazy => 1, isa => 'RegexpRef|CodeRef|HashRef|Undef',
    default => sub { qr{^(\d+)?x(\d+)?(?:-(.+))?$} }
);


has any_ext => (
    is => 'rw', lazy => 1, isa => 'Str|Undef',
    default => 'image'
);


has orig_ext => (
    is => 'rw', lazy => 1, isa => 'ArrayRef',
    default => sub { [qw( jpg png gif jpeg )] }
);


has memory_limit => (
    is => 'rw', lazy => 1, isa => 'Int|Undef',
    default => 10_000_000 # bytes
);


has jpeg_quality => (
    is => 'rw', lazy => 1, isa => 'Int|Undef',
    default => undef
);


has width => (
    is => 'rw', lazy => 1, isa => 'Int|Undef',
    default => undef
);


has height => (
    is => 'rw', lazy => 1, isa => 'Int|Undef',
    default => undef
);


has flags => (
    is => 'rw', lazy => 1, isa => 'HashRef|Undef',
    default => undef
);

sub call {
    my ($self,$env) = @_;
    my $path = $env->{PATH_INFO};
    my @param;

    if ( defined $self->path ) {
        my ($m) = _match($path,$self->path);
        return $self->app->($env) unless $m;
    }

    my @m = _match($path,$self->match);
    return $self->app->($env) unless @m;
    ($path, my $size, my $ext) = @m;
    return $self->app->($env) unless $path and $ext;

    if ( defined $size ) {
        @param = _unroll(_match($size,$self->size));
        return $self->app->($env) unless @param;
    }

    my $res = $self->fetch_orig($env,$path);
    return $self->app->($env) unless $res;

    ## Post-process the response with a body filter
    $self->response_cb( $res, sub {
        my $res = shift;
        my $orig_ct = Plack::Util::header_get( $res->[1], 'Content-Type' );
        my $ct;
        if ( defined $self->any_ext and $ext eq $self->any_ext ) {
            $ct = Plack::Util::header_get( $res->[1], 'Content-Type' );
        } else {
            $ct = Plack::MIME->mime_type(".$ext");
            Plack::Util::header_set( $res->[1], 'Content-Type', $ct );
        }
        return $self->body_scaler( $ct, $orig_ct, @param );
    });
}

## Helper for matching a Scalar value against CodeRef, HashRef,
## RegexpRef or Str. The first argument may be modified during match.
sub _match {
    my @match;
    for ( $_[0] ) {
        my $match = $_[1];
        @match =
          'CODE' eq ref $match ? $match->($_) :
          'HASH' eq ref $match ? $match->{$_} :
        'Regexp' eq ref $match ? $_ =~ $match :
                defined $match ? (substr($_,0,length $match) eq $match ? ($match) : ()) :
                                 undef;
    }
    return @match;
}

## Helper for extracting (width,height,flags) from
## HashRef or ArrayRef.
sub _unroll {
    return unless @_;
    for ( $_[0] ) {
        ## Config::General style hash of hashrefs.
        if ( ref eq 'HASH' ) {
            my %e = %{$_};
            return (delete @e{'width','height'}, \%e);
        ## Manual config friendly hash of arraysrefs.
        } elsif ( ref eq 'ARRAY' ) {
            return @{$_};
        }
    }
    return @_;
}


sub fetch_orig {
    my ($self,$env,$basename) = @_;

    for my $ext ( @{$self->orig_ext} ) {
        local $env->{PATH_INFO} = "$basename.$ext";
        my $r = $self->app->($env);
        return $r unless ref $r eq 'ARRAY' and $r->[0] == 404;
    }
    return;
}


sub body_scaler {
    my $self = shift;
    my @args = @_;

    my $buffer = q{};
    my $filter_cb = sub {
        my $chunk = shift;

        ## Buffer until we get EOF
        if ( defined $chunk ) {
            $buffer .= $chunk;
            return q{}; #empty
        }

        ## Return EOF when done
        return if not defined $buffer;

        ## Process the buffer
        my $img = $buffer ? $self->image_scale(\$buffer,@args) : '';
        undef $buffer;
        return $img;
    };

    return $filter_cb;
}


sub image_scale {
    my ($self, $bufref, $ct, $orig_ct, $width, $height, $flags) = @_;

    ## $flags can be a HashRef, or it's parsed as a string
    my %flag = 'HASH' eq ref $flags ? %{ $flags } :
    map { (split /(?<=\w)(?=\d)/, $_, 2)[0,1]; } split '-', $flags || '';

    $width  = $self->width      if defined $self->width;
    $height = $self->height     if defined $self->height;
    %flag   = %{ $self->flags } if defined $self->flags;

    my $owidth  = $width;
    my $oheight = $height;

    if ( defined $flag{z} and $flag{z} > 0 ) {
        $width  *= 1 + $flag{z} / 100 if $width;
        $height *= 1 + $flag{z} / 100 if $height;
    }

    my $output;
    if (defined $orig_ct and $orig_ct eq 'application/pdf') {
        try {
            Class::Load::load_class('Image::Magick::Thumbnail::PDF');
            Class::Load::load_class('File::Temp');
            my $in = File::Temp->new( SUFFIX => '.pdf' );
            my $out = File::Temp->new( SUFFIX => '.png' );
            $in->write( $$bufref ); $in->close;
            Image::Magick::Thumbnail::PDF::create_thumbnail(
                $in->filename, $out->filename, $flag{p}||1, {
                    frame => 0, normalize => 0,
                    restriction => max($width, $height),
                }
            );
            my $pdfdata;
            $out->seek( 0, 0 );
            $out->read( $pdfdata, 9999999 );
            $bufref = \$pdfdata;
        } catch {
            carp $_;
            $output = $$bufref;
        };
    }
    try {
        my $img = Image::Scale->new($bufref)
            or die 'Invalid data / image format not recognized';

        if ( exists $flag{crop} and defined $width and defined $height ) {
            my $ratio = $img->width / $img->height;
            $width  = max $width , $height * $ratio;
            $height = max $height, $width / $ratio;
        } elsif ( exists $flag{fit} and defined $width and defined $height ) {
            my $ratio = $img->width / $img->height;
            $width  = min $width , $height * $ratio;
            $height = min $height, $width / $ratio;
        }

        unless ( defined $width or defined $height ) {
            ## We want to keep the size, but Image::Scale
            ## doesn't return data unless we call resize.
            $width = $img->width; $height = $img->height;
        }
        $img->resize({
            defined $width  ? (width  => $width)  : (),
            defined $height ? (height => $height) : (),
            exists  $flag{fill} ? (keep_aspect => 1) : (),
            defined $flag{fill} ? (bgcolor => hex $flag{fill}) : (),
            defined $self->memory_limit ?
                (memory_limit => $self->memory_limit) : (),
        });

        $output = $ct eq 'image/jpeg' ? $img->as_jpeg($self->jpeg_quality || ()) :
                  $ct eq 'image/png'  ? $img->as_png :
                  die "Conversion to '$ct' is not implemented";
    } catch {
        carp $_;
        $output = $$bufref;
    };

    if ( defined $owidth  and $width  > $owidth or
         defined $oheight and $height > $oheight ) {
        try {
            Class::Load::load_class('Imager');
            my $img = Imager->new;
            $img->read( data => $output ) || die;
            my $crop = $img->crop(
                defined $owidth  ? (width  => $owidth)  : (),
                defined $oheight ? (height => $oheight) : (),
            );
            $crop->write( data => \$output, type => (split '/', $ct)[1] );
        } catch {
            carp $_;
        };
    }

    return $output;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Plack::Middleware::Image::Scale - Resize jpeg and png images on the fly

=head1 VERSION

version 0.011

=head1 SYNOPSIS

    ## example1.psgi
    use Plack::Builder;
    use Plack::Middleware::Image::Scale;
    my $app = sub { return [200,[],[]] };

    builder {
        enable 'ConditionalGET';
        enable 'Image::Scale';
        enable 'Static', path => qr{^/images/};
        $app;
    };

A request to /images/foo_40x40.png will use images/foo.(png|jpg|gif|jpeg) as
original, scale it to 40x40 px size and convert to PNG format.

    ## example2.psgi
    use Plack::Builder;
    use Plack::App::File;
    use Plack::Middleware::Image::Scale;
    my $app = sub { return [200,['Content-Type'=>'text/plain'],['hello']] };

    my $thumber = builder {
        enable 'ConditionalGET';
        enable 'Image::Scale',
            width => 200, height => 100,
            flags => { fill => 'ff00ff' };
        Plack::App::File->new( root => 'images' );
    };

    builder {
        mount '/thumbs' => $thumber;
        mount '/' => $app;
    };

A request to /thumbs/foo.png will use images/foo.(png|jpg|gif|jpeg) as original,
scale it small enough to fit 200x100 px size, fill extra borders (top/down or
left/right, depending on the original image aspect ratio) with cyan
background, and convert to PNG format. Also clipping is available, see
L</CONFIGURATION>.

=head1 DESCRIPTION

Scale and convert images to the requested format on the fly. By default the
size and other scaling parameters are extracted from the request URI.  Scaling
is done with L<Image::Scale>.

The original image is not modified or even accessed directly by this module.
The converted image is not cached, but the request can be validated
(If-Modified-Since) against original image without doing the image processing.
This middleware should be used together a cache proxy, that caches the
converted images for all clients, and implements content validation.

The response headers (like Last-Modified or ETag) are from the original image,
but body is replaced with a PSGI L<content
filter|Plack::Middleware/RESPONSE_CALLBACK> to do the image processing.  The
original image is fetched from next middleware layer or application with a
normal PSGI request. You can use L<Plack::Middleware::Static>, or
L<Catalyst::Plugin::Static::Simple> for example.

See L</CONFIGURATION> for various size/format specifications that can be used
in the request URI, and L</ATTRIBUTES> for common configuration options
that you can use when constructing the middleware.

=head1 ATTRIBUTES

=head2 path

Must be a L<RegexpRef|Moose::Util::TypeConstraints/Default_Type_Constraints>,
L<CodeRef|Moose::Util::TypeConstraints/Default_Type_Constraints>,
L<Str|Moose::Util::TypeConstraints/Default_Type_Constraints> or
L<Undef|Moose::Util::TypeConstraints/Default_Type_Constraints>.

The L<PATH_INFO|PSGI/The_Environment> is compared against this value to
evaluate if the request should be processed. Undef (the default) will match
always.  C<PATH_INFO> is topicalized by settings it to C<$_>, and it may be
rewritten during C<CodeRef> matching. Rewriting can be used to relocate image
paths, much like C<path> parameter for L<Plack::Middleware::Static>.

If path matches, next it will be compared against L</name>. If path doesn't
match, the request will be delegated to the next middleware layer or
application.

=head2 match

Must be a L<RegexpRef|Moose::Util::TypeConstraints/Default_Type_Constraints>,
or L<CodeRef|Moose::Util::TypeConstraints/Default_Type_Constraints>.

The L<PATH_INFO|PSGI/The_Environment>, possibly rewritten during L</path>
matching, is compared against this value to extract C<name>, C<size>
and C<ext>. The default value is:

    qr{^(.+)(?:_(.+?))?(?:\.(jpe?g|png|image))$}

The expression is evaluated in array context and may return three elements:
C<name>, C<size> and C<ext>. Returning an empty array means no match.
Non-matching requests are delegated to the next middleware layer or
application.

If the path matches, the original image is fetched from C<name>.L</orig_ext>,
scaled with parameters extracted from C<size> and converted to the content type
defined by C<ext>. See also L</any_ext>.

=head2 size

Must be a L<RegexpRef|Moose::Util::TypeConstraints/Default_Type_Constraints>,
L<CodeRef|Moose::Util::TypeConstraints/Default_Type_Constraints>,
L<HashRef|Moose::Util::TypeConstraints/Default_Type_Constraints>,
L<Undef|Moose::Util::TypeConstraints/Default_Type_Constraints>.

The C<size> extracted by L</match> is compared against this value to evaluate
if the request should be processed, and to map it into width, height and flags
for image processing. Undef will match always and use default width, height
and flags as defined by the L</ATTRIBUTES>. The default value is:

    qr{^(\d+)?x(\d+)?(?:-(.+))?$}

The expression is evaluated in array context and may return three elements;
C<width>, C<height> and C<flags>. Returning an empty array means no match.
Non-matching requests are delegated to the next middleware layer or
application.

Optionally a hash reference can be returned. Keys C<width>, C<height>, and any
remaining keys as an hash reference, will be unrolled from the hash reference.

=head2 any_ext

If defined and request C<ext> is equal to this, the content type of the original
image is used in the output. This means that the image format of the original
image is preserved. Default is C<image>.

=head2 orig_ext

L<ArrayRef|Moose::Util::TypeConstraints/Default_Type_Constraints>
of possible original image formats. See L</fetch_orig>.

=head2 memory_limit

Memory limit for the image scaling in bytes, as defined in
L<Image::Scale|Image::Scale/resize(_\%OPTIONS_)>.

=head2 jpeg_quality

JPEG quality, as defined in
L<Image::Scale|Image::Scale/as_jpeg(_[_$QUALITY_]_)>.

=head2 width

Use this to set and override image width.

=head2 height

Use this to set and override image height.

=head2 flags

Use this to set and override image processing flags.

=head1 METHODS

=head2 fetch_orig

Call parameters: PSGI request HashRef $env, Str $basename.
Return value: PSGI response ArrayRef $res.

The original image is fetched from the next layer or application.  All
possible extensions defined in L</orig_ext> are tried in order, to search for
the original image. All other responses except a straight 404 (as returned by
L<Plack::Middleware::Static> for example) are considered matches.

=head2 body_scaler

Call parameters: @args. Return value: PSGI content filter CodeRef $cb.

Create the content filter callback and return a CodeRef to it. The filter will
buffer the data and call L</image_scale> with parameters C<@args> when EOF is
received, and finally return the converted data.

=head2 image_scale

Call parameters: ScalarRef $buffer, String $ct, Int $width, Int $height, HashRef|Str $flags.
Return value: $imagedata

Read image from $buffer, scale it to $width x $height and
return as content-type $ct. Optional $flags to specify image processing
options like background fills or cropping.

=head1 CONFIGURATION

The default match pattern for URI is
"I<...>_I<width>xI<height>-I<flags>.I<ext>".

If URI doesn't match, the request is passed through. Any number of flags can
be specified, separated with C<->.  Flags can be boolean (exists or doesn't
exist), or have a numerical value. Flag name and value are separated with a
zero-width word to number boundary. For example C<z20> specifies flag C<z>
with value C<20>.

=head2 width

Width of the output image. If not defined, it can be anything
(to preserve the image aspect ratio).

=head2 height

Height of the output image. If not defined, it can be anything
(to preserve the image aspect ratio).

=head2 flags: fill

Image aspect ratio is preserved by scaling the image to fit within the
specified size. This means scaling to the smaller or the two possible sizes
that preserve aspect ratio.  Extra borders of background color are added to
fill the requested image size exactly.

    /images/foo_400x200-fill.png

If fill has a value, it specifies the background color to use. Undefined color
with png output means transparent background.

=head2 flags: crop

Image aspect ratio is preserved by scaling and cropping from middle of the
image. This means scaling to the bigger of the two possible sizes that
preserve the aspect ratio, and then cropping to the exact size.

=head2 flags: fit

Image aspect ratio is preserved by scaling the image to the smaller of the two
possible sizes. This means that the resulting picture may have one dimension
smaller than specified, but cropping or filling is avoided.

See documentation in distribution directory C<doc> for a visual explanation.

=head2 flags: z

Zoom the original image N percent bigger. For example C<z20> to zoom 20%.
Zooming applies only to explicitly defined width and/or height, and it does
not change the crop size.

    /images/foo_40x-z20.png

=head1 EXAMPLES

    ## see example4.psgi

    my %imagesize = Config::General->new('imagesize.conf')->getall;

    # ...

    enable 'Image::Scale', size => \%imagesize;

A request to /images/foo_medium.png will use images/foo.(png|jpg|gif|jpeg) as
original. The size and flags are taken from the configuration file as
parsed by Config::General.

    ## imagesize.conf

    <medium>
        width   200
        height  100
        crop
    </medium>
    <big>
        width   300
        height  100
        crop
    </big>
    <thumbred>
        width   50
        height  100
        fill    ff0000
    </thumbred>

For more examples, browse into directory
L<eg|http://cpansearch.perl.org/src/PNU/> inside the distribution
directory for this version.

=head1 CAVEATS

The cropping requires L<Imager>. This is a run-time dependency, and
fallback is not to crop the image to the expected size.

=head1 SEE ALSO

L<Image::Scale>

L<Imager>

L<Plack::App::ImageMagick>

=head1 AUTHOR

Panu Ervamaa <pnu@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011-2016 by Panu Ervamaa.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
