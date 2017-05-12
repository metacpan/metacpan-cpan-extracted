package Rudesind::Image;

use strict;

use Rudesind::Captioned;

use Class::Roles does => 'Rudesind::Captioned';

use File::Basename ();
use File::Path ();
use File::Slurp ();
use Image::Magick;
use Image::Size ();
use Params::Validate qw( validate UNDEF SCALAR ARRAYREF );
use Path::Class ();

use Rudesind::Config;


sub new
{
    my $class = shift;
    my %p = validate( @_,
                      { file   => { type => SCALAR },
                        path   => { type => SCALAR },
                        config => { isa => 'Rudesind::Config' },
                      },
                    );

    # XXX - check if image module can handle this type

    my ( $w, $h ) = Image::Size::imgsize( $p{file} );

    return bless { %p,
                   dir => Path::Class::dir( File::Basename::dirname( $p{file} ) ),
                   height => $h,
                   width  => $w,
                 }, $class;
}

sub file   { $_[0]->{file} }
sub path   { $_[0]->{path} }
sub config { $_[0]->{config} }

sub uri    { $_[0]->{path} . '.html' }

sub height { $_[0]->{height} }
sub width  { $_[0]->{width} }

sub filename { File::Basename::basename( $_[0]->file ) }
sub title    { $_[0]->filename }

sub gallery
{
    Rudesind::Gallery->new( path   => File::Basename::dirname( $_[0]->path ),
                            config => $_[0]->config );
}

sub _transforms
{
    my $config = $_[0]->config;

    return
    { default   =>
      { max_width   => $config->image_page_max_width,
        max_height  => $config->image_page_max_height,
      },
      thumbnail =>
      { max_width   => $config->thumbnail_max_width,
        max_height  => $config->thumbnail_max_height
      },
      double    => '_double_size',

      'rotate-90'  =>
      { rotate => 90,
        max_width   => $config->image_page_max_width,
        max_height  => $config->image_page_max_height,
      },
      'rotate-270'  =>
      { rotate => 270,
        max_width   => $config->image_page_max_width,
        max_height  => $config->image_page_max_height,
      },
      'rotate-180'  =>
      { rotate => 180,
        max_width   => $config->image_page_max_width,
        max_height  => $config->image_page_max_height,
      },
    };
}

sub _double_size
{
    my $self = shift;

    my $height =
        ( $self->height * 2 > $self->config->image_page_max_width * 2
          ? $self->config->image_page_max_width * 2
          : $self->height * 2
        );

    my $width =
        ( $self->width * 2 > $self->config->image_page_max_width * 2
          ? $self->config->image_page_max_width * 2
          : $self->width * 2
        );

    return ( width => $width, height => $height );
}

sub thumbnail_uri { $_[0]->transformed_image_uri( transforms => 'thumbnail' ) }
sub has_thumbnail { -f $_[0]->thumbnail_image_file }
sub thumbnail_image_file { $_[0]->transformed_image_file( transforms => 'thumbnail' ) }

sub transformed_image_uri
{
    my $self = shift;

    my $file = $self->make_transformed_image_file(@_);

    my $root = $self->config->root_dir;
    my $image_uri_root = $self->config->image_uri_root;

    $file =~ s/^\Q$root\E/$image_uri_root/;

    $file =~ s{\\}{/}g;

    return $file;
}

sub has_transformed_image_file
{
    my $self = shift;

    -f $self->transformed_image_file(@_);
}

sub make_transformed_image_file
{
    my $self = shift;

    my $file = $self->transformed_image_file(@_);

    return $file if -f $file;

    $self->_transform( $self->_transform_params(@_),
                       output_file => $file,
                     );

    return $file;
}

sub transformed_image_file
{
    my $self = shift;
    my %transform = $self->_transform_params(@_);

    my $file = $self->file;

    my $image_dir = $self->config->image_dir;

    my $t = join '-', sort ( keys %transform, values %transform );
    my $transform_dir = Path::Class::dir( $self->config->image_cache_dir, $t );

    $file =~ s/\Q$image_dir\E/$transform_dir/;

    return $file;
}

sub _transform_params
{
    my $self = shift;
    my %p = validate( @_, { transforms => { type => SCALAR | ARRAYREF,
                                            default => [ 'default' ] },
                          },
                    );

    my %transform;
    foreach my $name ( ref $p{transforms} ? @{ $p{transforms} } : $p{transforms} )
    {
        my $t = $self->_transforms->{$name};

        %transform = ( %transform,
                       ref $t ? %$t : $self->$t()
                     );
    }

    return %transform;
}

sub _transform
{
    my $self = shift;
    my %p = validate( @_,
                      { max_width  => { type    => SCALAR,
                                        default => undef,
                                        depends => 'max_height',
                                      },
                        max_height => { type    => SCALAR,
                                        default => undef,
                                        depends => 'max_width',
                                      },
                        width      => { type    => SCALAR,
                                        default => $self->width,
                                      },
                        height     => { type    => SCALAR,
                                        default => $self->height,
                                      },
                        rotate     => { type    => SCALAR,
                                        default => 0,
                                      },
                        output_file => { type => SCALAR },
                      },
                    );

    my $img = Image::Magick->new;
    $img->Read( filename => $self->file );

    if ( $p{max_width} && $p{max_height} )
    {
        if ( $p{max_width}  < $img->Get('width')
             ||
             $p{max_height} < $img->Get('height')
           )
        {
            my $width_r  = $p{max_width}  / $img->get('width');
            my $height_r = $p{max_height} / $img->get('height');

            my $ratio;
            $ratio = $height_r < $width_r ? $height_r : $width_r;

            $img->Scale( width  => int( $img->get('width') * $ratio ),
                         height => int( $img->get('height') * $ratio ),
                       );
        }
    }
    elsif ( $p{height} != $self->height
            ||
            $p{width}  != $self->width
          )
    {
        $img->Scale( height => $p{height},
                     width  => $p{width},
                   );
    }

    if ( $p{rotate} )
    {
        $img->Rotate( degrees => $p{rotate} );
    }

    File::Path::mkpath( File::Basename::dirname( $p{output_file} ), 0, 0755 );

    my $q = $img->Get('quality');
    $img->Write( filename => $p{output_file},
                 ( defined $q ? ( quality  => $q ) : () ),
                 type     => 'Palette',
               );
}

sub _caption_file
{
    my $self = shift;

    return $self->{dir}->file( '.' . $self->filename . '.caption' );
}

{
    my $ext =
        ( join '|',
          map { "\Q.$_\E" }
          qw( gif jpg jpeg jpe png )
        );

    sub image_extension_re { qr/(?:$ext)$/i }
}



1;

__END__

=pod

=head1 NAME

Rudesind::Image - An object representing a single image

=head1 SYNOPSIS

  use Rudesind::Gallery;

  my $img = Rudesind::Gallery->image('IMG_0101.JPG');

  print $img->file;

=head1 DESCRIPTION

This class represents a single image.  It provides methods for
accessing information on that image, as well as creating transformed
versions of the image (resizing, rotating, etc.).

=head1 CONSTRUCTOR

Image objects should be constructed by calling the C<image()> method
on a C<Rudesind::Gallery> object.

=head1 METHODS

This class provides the following methods:

=over 4

=item * file()

The filesystem path, with file name, for this object.

=item * filename()

Juse the filename, without the path.

=item * path()

The C<URI> path for this image.

=item * uri()

The value of C<path()> both with ".html" appended.  Provided for the
use of the Mason UI.  Use C<path()> instead.

=item * title()

A title for the image.  Currently, this is just the image's file name.

=item * config()

The C<Rudesind::Config> object given to the constructor.

=item * height()

The height of the image, in pixels.

=item * width()

The width of the image, in pixels.

=item * gallery()

The C<Rudesind::Gallery> object containing this image.

=item * thumbnail_uri()

The URI for a thumbnail version of the image.

Calling this method will generate the thumbnail image if a cached
version does not exist, using the
C<make_transformed_image_file('thumbnail')> method.

=item * thumbnail_image_file()

The filesystem path for this image's cached thumbnail.  This method
always returns a filename, whether or not the file actually exists.

=item * has_thumbnail()

Indicates whether or not there is a cached thumbnail for this image.

=item * transformed_uri(@transforms)

The URI for a transformed version of the image, based on the specified
transforms.

Calling this method will generate the transformed image if a cached
version does not exist, using the C<make_transformed_image_file()>
method.

=item * transformed_image_file(@transforms)

The filesystem path for this image's cached transformed version, based
on the specified transforms.  This method always returns a filename,
whether or not the file actually exists.

=item * has_transformed(@transforms)

Indicates whether or not there is a cached transformed version of this
image, based on the specified transforms.

=item * make_transformed_image_file(@transforms)

Creates a transformed version of the image according to the specified
transforms and stores it in the cached images directory, if one
doesn't already exist.

This method returns the filesystem path for the file.

=back

=head2 Transforms

For any method that accepts transforms, you can specify any of the following:

=over 4

=item * default

The default image size and orientation.  The maximum height and width
allowed are the "image_page_max_height" and "image_page_max_width"
configuration parameters.

=item * thumbnail

The thumnail height and width of the image.

=item * double

Doubles the image's size from the default, so that the maximum height
and width allowed are twice the "image_page_max_height" and
"image_page_max_width" configuration parameters.

=item * rotate-90

Rotate the image 90 degrees clockwise.  The maximum height and width
allowed are the "image_page_max_height" and "image_page_max_width"
configuration parameters.

=item * rotate-180

Rotate the image 180 degrees.  The maximum height and width allowed
are the "image_page_max_height" and "image_page_max_width"
configuration parameters.

=item * rotate-270

Rotate the image 270 degrees clockwise.  The maximum height and width
allowed are the "image_page_max_height" and "image_page_max_width"
configuration parameters.

=back

It is possible to pass multiple transforms at once, so you could do this:

  my $file = $image->make_transformed_image_file( 'double', 'rotate-90' );

This produces an image to which both the "double" and "rotate-90"
transforms have been applied, in the specified order.

=head2 Captions

This class uses the C<Rudesind::Captioned> role.

=cut
