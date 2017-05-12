package Tempest;

use strict;
use warnings;
use version;

use Carp;
use File::Basename;

=head1 NAME

Tempest - Flexible temperature-map/heat-map generator

=head1 DESCRIPTION

Tempest is implemented natively in multiple programming languages, including
Perl 5.  This implementation is "pure" Perl, meaning that there is no
C or XS code to configure or compile.  Installation entails the steps for any
modern CPAN module:

    perl Makefile.PL
    make
    make test
    make install

=head1 VERSION

Version 2010.09.26

Tempest API Version 2009.07.15

=cut

our $VERSION = qv('2010.09.26');
our $API_VERSION = qv('2009.07.15');

=head1 SYNOPSIS

This module exposes the Tempest API through class instantiation:

    use Tempest;
    
    # Create new instance
    $heatmap = new Tempest(
      'input_file' => 'screenshot.png',
      'output_file' => 'heatmap.png',
      'coordinates' => [ [0,10], [2,14], [2,14] ],
    ));
    
    # Configure as needed
    $heatmap->set_image_lib( Tempest::LIB_GD );
    
    # Generate and write heatmap image
    $heatmap->render();

=head1 CONSTANTS

These constants can be assigned to the C<image_lib> property to specify use
of a given image library for all image manipulations.

=head3 C<LIB_MAGICK>

For forcing use of L<Image::Magick|Image::Magick> support.

=head3 C<LIB_GMAGICK>

For forcing use of L<Graphics::Magick|Graphics::Magick> support.

=head3 C<LIB_GD>

For forcing use of L<GD|GD> support.

=cut

use constant LIB_MAGICK => 'Image::Magick';
use constant LIB_GMAGICK => 'Graphics::Magick';
use constant LIB_GD => 'GD';

=head1 PROPERTIES

=head2 Required Properties

=head3 C<input_file>

The generated heatmap will share the same dimensions as this image,
and - if indicated - will be overlaid onto this image with a given
opacity.

=cut

my %input_file;

=head3 C<output_file>

The generated heatmap will be written to this path, replacing any
existing file without warning.

=cut

my %output_file;

=head3 C<coordinates>

The contained x,y coordinates will mark the center of all plotted data
points in the heatmap.  Coordinates can - and in many cases are
expected to - be repeated.

=cut

my %coordinates;

=head2 Optional Properties

=head3 C<plot_file>

This image, expected to be greyscale, is used to plot data points for
each of the given coordinates.  Defaults to a bundled image, if none
is provided.

=cut

my %plot_file;

=head3 C<color_file>

This image, expected to be a true color vertical gradient, is used as a
color lookup table and is applied to the generated heatmap.  Defaults
to a bundled image, if none is provided.

=cut

my %color_file;

=head3 C<overlay>

If true, the heatmap is overlaid onto the input image with a given
opacity before being written to the filesystem.  Defaults to B<True>.

=cut

my %overlay;

=head3 C<opacity>

Indicates with what percentage of opaqueness to overlay the heatmap
onto the input image.  If 0, the heatmap will not be visible; if 100,
the input image will not be visible.  Defaults to b<50>.

=cut

my %opacity;

=head3 C<image_lib>

Indicates which supported image manipulation library should be used
for rendering operations.  Defaults to the first available from the
following:

=cut

my %image_lib;

my @_required = ('input_file', 'output_file', 'coordinates');
my @_optional = ('plot_file', 'color_file', 'overlay', 'opacity', 'image_lib');

=head1 METHODS

=head2 C<new>

Class constructor, accepts a hash of named arguments corresponding to
the class' own getter and setter methods.

    $heatmap = new Tempest(
      'input_file' => 'screenshot.png',
      'output_file' => 'heatmap.png',
      'coordinates' => [ [0,10], [2,14], [2,14] ],
    );

=cut

sub new {
    my $class = shift;
    
    croak('Bad parameter list, should be a hash') if @_ % 2;
    my %params = @_;
    
    # inside-out object model
    my $self = bless \(my $dummy), $class;
    
    # set defaults
    $plot_file{$self} = dirname(__FILE__) . '/Tempest/data/plot.png';
    $color_file{$self} = dirname(__FILE__) . '/Tempest/data/clut.png';
    $overlay{$self} = 1;
    $opacity{$self} = 50;
    $image_lib{$self} = $self->_calc_image_lib();
    
    # for all required parameters..
    for my $param_name (@_required) {
        # ..ensure they were provided
        if(!exists $params{$param_name}) {
            croak("Missing required parameter '$param_name'");
        }
        
        # ..and call each of their setters
        eval('$self->set_' . $param_name . '($params{$param_name})');
    }
    
    # for all optional parameters..
    for my $param_name (@_optional) {
        # ..if they were provided..
        if(exists $params{$param_name}) {
            # ..call their setters
            eval('$self->set_' . $param_name . '($params{$param_name})');
        }
    }
    
    return $self;
}

=head2 C<render>

Initiates processing of provided arguments, and writes a heatmap image
to the filesystem.  Returns B<True> on success.

    die('Rendering failed') if ! $heatmap->render();

=cut

sub render {
    my $self = shift;
    
    my $lib_name = ucfirst(lc($image_lib{$self}));
    $lib_name =~ s/\W//g;
    
    my $result = eval('require Tempest::'.$lib_name.'; return Tempest::'.$lib_name.'::render($self);');
    croak($@) if $@;
    return $result;
}

=head2 C<version>

Returns the version number of the current release.

    die('Outdated') if $heatmap->version() lt '2009.06.15';

=cut

sub version {
    return $VERSION;
}

=head2 C<api_version>

Returns the version number of the currently supported Tempest API.

    die('API is outdated') if $heatmap->api_version() lt '2009.06.15';

=cut

sub api_version {
    return $API_VERSION;
}

=head2 Setters

Each setter method assigns a new value to its respective property.
The setters also return the current class instance, so they can be 'chained'.

For example, if we wanted to change the C<image_lib> used for image processing,
and immediately render the resulting heatmap:

    # render heatmap with Image::Magick support
    $heatmap ->set_image_lib( Tempest::LIB_MAGICK ) ->render();

=head2 Getters

Each getter method returns the current value of its respective property.

For example, if we wanted to retrieve the C<coordinates> to be rendered and
immediately output them with the L<Data::Dumper|Data::Dumper> module:

    use Data::Dumper;
    print Dumper( $heatmap->get_coordinates() );

=cut

sub set_input_file {
    my $self = shift;
    my $input_file = shift;
    
    if(-r $input_file) {
        $input_file{$self} = $input_file;
    }
    else {
        croak("Image '$input_file' is not readable");
    }
    
    return $self;
}

sub get_input_file {
    my $self = shift;
    return $input_file{$self};
}


sub set_output_file {
    my $self = shift;
    my $output_file = shift;
    
    if((! -e $output_file) || -w $output_file) {
        $output_file{$self} = $output_file;
    }
    else {
        croak("Image '$output_file' is not writable");
    }
    
    return $self;
}

sub get_output_file {
    my $self = shift;
    return $output_file{$self};
}


sub set_coordinates {
    my $self = shift;
    my $coordinates = shift;
    
    # verify an array of 2-element arrays
    if(ref($coordinates) ne 'ARRAY') {
        croak('Bad coordinates: not an array reference');
    }
    
    for my $pair (@{$coordinates}) {
        if(ref($pair) ne 'ARRAY' || scalar(@{$pair}) != 2) {
            croak('Bad coordinate pair: ' . join(',', @{$pair}));
        }
    }
    
    $coordinates{$self} = $coordinates;
    return $self;
}

sub get_coordinates {
    my $self = shift;
    return $coordinates{$self};
}


sub set_plot_file {
    my $self = shift;
    my $plot_file = shift;
    
    if(-r $plot_file) {
        $plot_file{$self} = $plot_file;
    }
    else {
        croak("Image '$plot_file' is not readable");
    }
    
    return $self;
}

sub get_plot_file {
    my $self = shift;
    return $plot_file{$self};
}


sub set_color_file {
    my $self = shift;
    my $color_file = shift;
    
    if(-r $color_file) {
        $color_file{$self} = $color_file;
    }
    else {
        croak("Image '$color_file' is not readable");
    }
    
    return $self;
}

sub get_color_file {
    my $self = shift;
    return $color_file{$self};
}


sub set_overlay {
    my $self = shift;
    my $overlay = shift;
    
    $overlay{$self} = $overlay ? 1 : 0;
    return $self;
}

sub get_overlay {
    my $self = shift;
    return $overlay{$self};
}


sub set_opacity {
    my $self = shift;
    my $opacity = shift;
    
    if($opacity >=0 && $opacity <= 100) {
        $opacity{$self} = $opacity;
    }
    else {
        croak("'$opacity' is not a valid percentage (integer from 0 to 100)");
    }
    
    return $self;
}

sub get_opacity {
    my $self = shift;
    return $opacity{$self};
}


sub set_image_lib {
    my $self = shift;
    my $image_lib = shift;
    
    if($self->has_image_lib($image_lib)) {
        $image_lib{$self} = $image_lib;
    }
    else {
        croak("Image library '$image_lib' could not be found");
    }
    
    return $self;
}

sub get_image_lib {
    my $self = shift;
    return $image_lib{$self};
}

=head2 C<has_image_lib>

Returns true value if the given image library is available.

    die('GD is unavailable') if ! $heatmap->has_image_lib(Tempest::LIB_GD);

=cut

sub has_image_lib {
    my $self = shift;
    my $image_lib = shift;
    
    # work as instance method or static method
    if(ref($self) ne 'Tempest') {
        $image_lib = $self;
        undef $self;
    }
    
    if($image_lib eq LIB_MAGICK || $image_lib eq LIB_GMAGICK || $image_lib eq LIB_GD) {
        eval("no warnings 'all'; require $image_lib;");
        if(!$@) {
            return 1;
        }
        else {
            return 0;
        }
    }
    else {
        croak("Image library '$image_lib' is not supported");
    }
}

# Determine optimal supported (and available) image library to use
# not intended to be public, so no need to document it
sub _calc_image_lib {
    for my $image_lib (LIB_MAGICK, LIB_GMAGICK, LIB_GD) {
        if(Tempest::has_image_lib($image_lib)) {
            return $image_lib;
        }
    }
    
    croak('No supported image library could be found');
}

=head2 C<DESTROY>

Class destructor, destroys the class instance.  Normally not invoked directly.

    # free up resources
    $heatmap->DESTROY();

=cut

sub DESTROY {
    my $self = shift;
    
    for my $param_name (@_required, @_optional) {
        {
            no strict 'refs';
            delete ${$param_name}{$self};
        };
    }
}

=head1 COPYRIGHT & LICENSE

Copyright 2010 Evan Kaufman, all rights reserved.

This program is released under the MIT license.

L<http://www.opensource.org/licenses/mit-license.php>

=head1 ADDITIONAL LINKS

=over

=item Tempest on Google Code:

L<http://code.google.com/p/image-tempest/>

=back

=cut

1;
