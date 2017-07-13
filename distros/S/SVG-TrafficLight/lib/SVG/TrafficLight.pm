=head1 NAME

SVG::TrafficLight - Perl extension to produce SVG diagrams of traffic lights.

=head1 DESCRIPTION

Perl extension to produce SVG diagrams of traffic lights.

=head1 SYNOPSIS

    use SVG::TrafficLight;

    my $tl = SVG::TrafficLight->new; # default image
    print $some_file_handle $tl->xmlify;

    my $tl2 = SVG::TrafficLight->new({
      sequence => [
        { red => 1, amber => 1, green => 1 }, # all lights on
        { red => 0, amber => 0, green => 0 }, # all lights off
      ],
    });

=cut

package SVG::TrafficLight;

use Moose;
use SVG;

our $VERSION = '0.0.3';

=head1 ATTRIBUTES AND METHODS

=head2 radius()

Returns the radius of the circles used to draw the traffic lights. The default
is 50, but this can be altered when creating the object.

    my $tl = SVG::TrafficLight->new({ radius => 1000 });

=cut

has radius => (
  is      => 'ro',
  isa     => 'Num',
  default => 50,
);

=head2 diameter

Returns the diameter of the circles used to draw the traffic lights. This is
just twice the radius. The default is 100. Change it by setting a different
radius.

=cut

sub diameter {
  my $self = shift;

  return $self->radius * 2;
}

=head2 padding

Returns a value which is used to pad various shapes in the image.

=over 4

=item *

The padding between the edge of the image and the traffic light block.

=item *

The padding between two traffic light blocks in the sequence.

=item *

The padding between the edge of a traffic light block and the lights
contained within it.

=item *

The padding between two vertically stacked traffic lights within a block.

=back

The default value is half the radius of a traffic light circle. This can
be set when creating the object;

    my $tl = SVG::TrafficLight->new({ padding => 100 });

=cut 

has padding => (
  is         => 'ro',
  isa        => 'Num',
  lazy_build => 1,
);

sub _build_padding {
  return shift->radius * .5;
}

=head2 light_width

Returns the width of a traffic light. This is the diameter of a light plus
twice the padding (one padding for each side of the light).

=cut

has light_width => (
  is         => 'ro',
  isa        => 'Num',
  lazy_build => 1,
);

sub _build_light_width {
  my $self = shift;

  # A light is a diameter plus two paddings
  return $self->diameter + (2 * $self->padding);
}

=head2 light_height

Returns the height of a traffic light. This is the diameter of three lights
plus four times the padding (one at the top, one at the bottom and two between
lights in the block).

=cut

has light_height => (
  is         => 'ro',
  isa        => 'Num',
  lazy_build => 1,
);

sub _build_light_height {
  my $self = shift;

  # Height is three diameters + four paddings
  return (3 * $self->diameter) + (4 * $self->padding);
}

=head2 width

Returns the width of the SVG document.

This is the width of a traffic light block multiplied by the number of blocks
in the sequence plus padding on the left and right and padding between each
pair of lights.

=cut

has width => (
  is         => 'ro',
  isa        => 'Num',
  lazy_build => 1,
);

sub _build_width {
  my $self = shift;

  my $count_lights = scalar @{ $self->sequence };

  # One light is 2 * radius
  # + 2 * padding
  my $one_light = $self->light_width;

  # Multiply by the number of lights
  my $lights = $count_lights * $one_light;

  # Add padding at the edges and between the lights
  return ($count_lights + 1) * $self->padding + $lights;
}

=head2 height

Returns the height of the SVG document.

This is the height of a traffic light block plus padding at the top and
bottom.

=cut

has height => (
  is         => 'ro',
  isa        => 'Num',
  lazy_build => 1,
);

sub _build_height {
  my $self = shift;

  # Height of a light bank + two lots of padding
  return $self->light_height + (2 * $self->padding);
}

=head2 corner_radius

Returns the radius of the circles used to curve the corners of a traffic
light block. The default is 20. This can be changed when creating the object.

    my $tl = SVG::TrafficLight->new({ corner_radius => 500 });

=cut

has corner_radius => (
  is      => 'ro',
  isa     => 'Num',
  default => 20,
);

=head2 svg

This is the SVG object that used to create the SVG document. A standard
object is created for you. It's possible to pass in your own when
creating the object.

    my $tl = SVG::TrafficLight->new({
      svg => SVG->new(width => $width, height => $height,
    });

=cut

has svg => (
  is         => 'ro',
  isa        => 'SVG',
  lazy_build => 1,
  handles    => [ qw(rect circle xmlify) ],
);

sub _build_svg {
  my $self = shift;

  return SVG->new(
    width  => $self->width,
    height => $self->height,
  );
}

=head2 colours

This defines the colours used to draw the traffic lights. The value must be
a reference to a hash. The hash must contain three keys - C<red>, C<amber>,
and C<green>. The values are references to two-element arrays. The first
element in each array is the colour used when the light is off and the 
second is the colour used when the light is on.

The values of the colours can be anything that is recognised as a colour in
SVG. These are either colour names (e.g. 'red') or RGB definitions (e.g.
'rgb(255,0,0,)'.

The default values can be overridden when creating the object.

    my $tl = SVG::TrafficLight->new({
      colours => {
        red   => [ ... ],
        amber => [ ... ],
        green => [ ... ],
      }.
    });

=cut

has colours => (
  is      => 'ro',
  isa     => 'HashRef',
  default => sub { {
    red   => ['rgb(63,0,0)',  'red'],
    amber => ['rgb(59,29,0)', 'orange'],
    green => ['rgb(0,63,0)',  'green'],
  } },
);

=head2 sequence

Defines a sequence of traffic lights to display. This is an array reference.
Each element in the array is a hash reference which defines which of the
three lights are on or off.

The default sequence demonstates the full standard British traffic light
sequence of green, amber, red, red and amber, green. This can be changed
when creating the object.

    my $tl = SVG::TrafficLight->new({
      sequence => [
        { red => 0, amber => 0, green => 0 },
        { red => 1, amber => 1, green => 1 },
      ],
    });

=cut

has sequence => (
  is => 'ro',
  isa => 'ArrayRef',
  default => sub { [{
    red   => 0,
    amber => 0,
    green => 1,
  }, {
    red   => 0,
    amber => 1,
    green => 0,
  }, {
    red   => 1,
    amber => 0,
    green => 0,
  }, {
    red   => 1,
    amber => 1,
    green => 0,
  }, {
    red   => 0,
    amber => 0,
    green => 1,
  }] },
);

sub BUILD {
  my $self = shift;

  for my $i (0 .. $#{$self->sequence}) {
    my $light_set_x = ($i * ($self->light_width + $self->padding))
                      + $self->padding;

    $self->rect(
      x      => $light_set_x,
      y      => $self->padding,
      width  => $self->light_width,
      height => $self->light_height,
      fill   => 'black',
      rx     => $self->corner_radius,
      ry     => $self->corner_radius,
    );

    my $light = 0;
    for my $l (qw[red amber green]) {
      my $fill = $self->colours->{$l}[$self->sequence->[$i]{$l}];

      $self->circle(
        cx   => $light_set_x + $self->padding + $self->radius,
        cy   => (2 * $self->padding) + $self->radius
                + $light * ($self->diameter + $self->padding),
        r    => $self->radius,
        fill => $fill,
      );
      ++$light;
    }
  }
}

=head1 AUTHOR

Dave Cross E<lt>dave@perlhacks.comE<gt>

=head1 COPYRIGHT

Copyright (c) 2017 Magnum Solutions Ltd. All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=head1 SEE ALSO

L<SVG>

=cut

1;
