=head1 NAME

SVG::ChristmasTree - Perl extension to draw Christmas trees with SVG

=head1 DESCRIPTION

Perl extension to draw Christmas trees with SVG

=head1 SYNOPSIS

    # Default tree
    my $tree = SVG::ChristmasTree->new;
    print $tree->as_xml;

    # Or change things
    my $tree = SVG::ChristmasTree->new({
      layers => 5,
      leaf_colour => 'rgb(0,255,0)',
      pot_colour => 'rgb(0,0,255)',
      star_color => 'rgb(255,0,0)',
    });
    print $tree->as_xml;

=cut

package SVG::ChristmasTree;

use strict;
use warnings;

use Moose;
use namespace::autoclean;
use SVG;
use Math::Trig qw[deg2rad tan];

with 'MooseX::Getopt';

our $VERSION = '0.0.7';

# Constants that we haven't made into attributes yet
use constant {
  TREE_WIDTH => 600,          # Width of the bottom tree layer
  TOP_ANGLE  => 90,           # Angle at the top of the tree triangles
  LAYER_SIZE_RATIO => (5/6),  # How much smaller each layer gets
  LAYER_STACKING => 0.5,      # How far up a layer triangle does the next one start
  POT_TOP_WIDTH => 300,       # Width of the top of the pot
  POT_BOT_WIDTH => 200,       # Width of the bottom of the pot
  TRUNK_WIDTH => 100,         # Width of the trunk
  BAUBLE_RADIUS => 20,        # Radius of a bauble
};

=head1 Methods

=head2 $tree = SVG::ChristmasTree->new(\%args)

Constructs and returns a new SVG::ChristmasTree object. With no arguments,
a default tree design is created, but it is possible to change that by
passing the following attributes to the method.

=over 4

=item width INT

The width of the tree diagram in "pixels". The default is 1,000.

=item layers INT

The number of layers in the tree. The default tree has four layers.

=item trunk_length INT

The length of the trunk in "pixels". The default length is 100.

=item leaf_colour STR

The colour of the tree's leaves. This must be defined as an SVG RGB value.
The default value is "rgb(0,127,0)".

=item bauble_colour STR

The colour of the baubles that hang on the tree. This must be defined as an
SVG RGB value. The default value is "rgb(212,175,55)".

=item trunk colour STR

The colour of the tree trunk. This must be defined as an SVG RGB value. The
default value is "rgb(139,69,19)".

=item pot_colour STR

The colour of the pot. This must be defined as an SVG RGB value. The default
value is "rgb(191,0,0)".

=item pot_height INT

The height of the pot in "pixels". The default height is 200.

=item star_colour STR

The colour of the star. This must be defined as an SVG RGB value. The default
value is "rgb(212,175,55)".

=item star_size INT

The size of the star in "pixels". The start will be in a square of the defined
size.The default size is 80.

=back

=head2 $tree->as_xml

Returns the SVG document as XML. You will usually want to store the returned
value in a variable, print it to C<STDOUT> or write it to a file.

=cut

has width => (
  isa => 'Int',
  is  => 'ro',
  default => 1_000,
);

has height => (
  isa => 'Int',
  is  => 'ro',
  lazy_build => 1,
  init_arg => undef,
);

# Height is calculated from all the other stuff
sub _build_height {
  my $self = shift;

  # Pot height ...
  my $height = $self->pot_height;
  # ... plus the trunk length ...
  $height += $self->trunk_length;
  # ... for most of the layers ...
  for (0 .. $self->layers - 2) {
    # ... add LAYER_STACKING of the height ...
    $height += $self->triangle_heights->[$_] * LAYER_STACKING;
  }
  # ... add all of the last layer ...
  $height += $self->triangle_heights->[-1];
  # ... and (finally) half of the star
  $height += $self->star_size / 2;

  return int($height + 0.5);
}

has triangle_heights => (
  isa => 'ArrayRef',
  is => 'ro',
  lazy_build => 1,
  init_arg => undef,
);

sub _build_triangle_heights {
  my $self = shift;

  my @heights;
  my $width = TREE_WIDTH;
  for (1 .. $self->layers) {
    push @heights, $self->_triangle_height($width, TOP_ANGLE);
    $width *= LAYER_SIZE_RATIO;
  }

  return \@heights;
}

sub _triangle_height {
  my $self = shift;
  my ($base, $top_angle) = @_;

  # Assume $top_angle is in degrees
  $top_angle = deg2rad($top_angle) / 2;
  # If I remember my trig correctly...
  return ($base / 2) / tan($top_angle);
}

has svg => (
  isa  => 'SVG',
  is   => 'ro',
  lazy_build => 1,
  init_arg => undef,
);

sub _build_svg {
  my $self = shift;

  return SVG->new(
    width => $self->width,
    height => $self->height,
  );
}

has layers => (
  isa => 'Int',
  is  => 'ro',
  default => 4,
);

has trunk_length => (
  isa => 'Int',
  is  => 'ro',
  default => 100,
);

has leaf_colour => (
  isa => 'Str',
  is  => 'ro',
  default => 'rgb(0,127,0)',
);

has bauble_colour => (
  isa => 'Str',
  is  => 'ro',
  default => 'rgb(212,175,55)',
);

has trunk_colour => (
  isa => 'Str',
  is  => 'ro',
  default => 'rgb(139,69,19)',
);

has pot_colour => (
  isa => 'Str',
  is  => 'ro',
  default => 'rgb(191,0,0)',
);

has star_colour => (
    isa => 'Str',
    is  => 'ro',
    default => 'rgb(212,175,55)',
);

has pot_height => (
  isa => 'Int',
  is  => 'ro',
  default => 200,
);

has star_size => (
    isa => 'Int',
    is  => 'ro',
    default => 80,
);

has triangles => (
  isa => 'ArrayRef',
  is => 'ro',
  lazy_build => 1,
  init_arg => undef,
);

sub _build_triangles {
  my $self = shift;

  my $width = TREE_WIDTH;
  my $tri_bottom = $self->height - $self->pot_height - $self->trunk_length;

  my @triangles;
  for (1 .. $self->layers) {
    push @triangles, $self->_triangle(TOP_ANGLE, $width, $tri_bottom);
    $width *= LAYER_SIZE_RATIO;
    $tri_bottom -= $triangles[-1]->{h} * LAYER_STACKING;
  }

  return \@triangles;
}

sub as_xml {
  my $self = shift;

  $self->pot;
  $self->trunk;

  for (@{$self->triangles}) {
    my $h = $self->_triangle(TOP_ANGLE, $_->{w}, $_->{b});
    $self->bauble($self->_mid_y - ($_->{w}/2), $_->{b});
    $self->bauble($self->_mid_y + ($_->{w}/2), $_->{b});
    $self->_coloured_shape(
      $_->{x}, $_->{y}, $self->leaf_colour,
    );
  }

  $self->star;

  return $self->svg->xmlify;
}

sub pot {
  my $self = shift;

  my $pot_top = $self->height - $self->pot_height;

  $self->_coloured_shape(
    [  $self->_mid_y - (POT_BOT_WIDTH / 2),
       $self->_mid_y - (POT_TOP_WIDTH / 2),
       $self->_mid_y + (POT_TOP_WIDTH / 2),
       $self->_mid_y + (POT_BOT_WIDTH / 2) ],
    [ $self->height, $pot_top, $pot_top, $self->height ],
    $self->pot_colour,
  );
}

sub trunk {
  my $self = shift;

  my $trunk_bottom = $self->height - $self->pot_height;
  my $trunk_top    = $trunk_bottom - $self->trunk_length;

  $self->_coloured_shape(
    [ $self->_mid_y - (TRUNK_WIDTH / 2), $self->_mid_y - (TRUNK_WIDTH / 2),
      $self->_mid_y + (TRUNK_WIDTH / 2), $self->_mid_y + (TRUNK_WIDTH / 2) ],
    [ $trunk_bottom, $trunk_top, $trunk_top, $trunk_bottom ],
    $self->trunk_colour,
  );
}

sub _triangle {
  my $self = shift;
  my ($top_angle, $base, $bottom) = @_;

  my ($x, $y);

  # Assume $top_angle is in degrees
  $top_angle = deg2rad($top_angle) / 2;
  # If I remember my trig correctly...
  my $height = ($base / 2) / tan($top_angle);

  $x = [ $self->_mid_y - ($base / 2), $self->_mid_y, $self->_mid_y + ($base / 2) ];
  $y = [ $bottom, $bottom - $height, $bottom ];

  return {
    x => $x,      # array ref of x points
    y => $y,      # array ref of y points
    h => $height, # height of the triangle
    w => $base,   # length of the base of the triangle
    b => $bottom, # y-coord of the bottom of the triangle
  };
}

sub bauble {
  my $self = shift;
  my ($x, $y) = @_;

  $self->svg->circle(
    cx => $x,
    cy => $y + BAUBLE_RADIUS,
    r => BAUBLE_RADIUS,
    style => {
      fill => $self->bauble_colour,
      stroke => $self->bauble_colour,
    },
  );
}

sub star {
  my $self = shift;
  my ($x, $y, $delta_x, $delta_y);

  $delta_x = $self->_mid_y;
  $delta_y = 0;

  # coordinates for a polyline star centered at 0,0
  $x = [ 0,  0.125, 0.5, 0.25, 0.375,  0, -0.375, -0.25, -0.5, -0.125, 0 ];
  $y = [ 0, 0.375, 0.375, 0.625, 1, 0.75,  1,  0.625,  0.375, 0.375, 0 ];

  # multiple by size
  $x = [map { $_ * $self->star_size } @$x];
  $y = [map { $_ * $self->star_size } @$y];

  # move to the placement we want (centered, on top of tree)
  $x = [map { $_ + $delta_x } @$x];
  $y = [map { $_ + $delta_y } @$y];

  $self->_coloured_shape(
      $x,
      $y,
      $self->star_colour,
  );
}

sub _mid_y {
  my $self = shift;

  return $self->width / 2;
}

sub _coloured_shape {
  my $self = shift;
  my ($x, $y, $colour) = @_;

  my $path = $self->svg->get_path(
    x => $x,
    y => $y,
    -type => 'polyline',
    -closed => 1,
  );

  $self->svg->polyline(
    %$path,
    style => {
      fill => $colour,
      stroke => $colour,
    },
  );
}

__PACKAGE__->meta()->make_immutable();

=head1 AUTHOR

Dave Cross <dave@perlhacks.com>

=head1 COPYRIGHT AND LICENCE

Copyright (c) 2018, Magnum Solutions Ltd. All Rights Reserved.

This library is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1;
