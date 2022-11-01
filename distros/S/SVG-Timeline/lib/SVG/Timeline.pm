=head1 NAME

SVG::Timeline - Create SVG timeline charts

=head1 SYNOPSIS

    use SVG::Timeline;

    my $tl = SVG::Timeline->new;

    $tl->add_event({
      start => 1914,
      end   => 1918,
      text  => 'World War I',
    });

    $tl->add_event({
      start => '1939-09-01', # 1 Sep 1939
      end   => '1945-05-08', # 8 May 1945
      text  => 'World War II',
    });

    print $tl->draw;

=head1 DESCRIPTION

This module allows you to easily create SVG documents that represent timelines.

An SVG timeline is a diagram with a list of years across the top and a
number of bars below. Each bar represents a period of time.

=head1 METHODS

=head2 new(\%options)

Creates and returns a new SVG::Timeline object.

Takes an optional hash reference containing configuration options. You
probably don't need any of these, but the following options are supported:

=over 4

=cut

package SVG::Timeline;

use 5.014;

our $VERSION = '0.1.3';

use Moose;
use Moose::Util::TypeConstraints;
use SVG;
use List::Util qw[min max];
use Carp;

use SVG::Timeline::Event;

subtype 'ArrayOfEvents', as 'ArrayRef[SVG::Timeline::Event]';

coerce 'ArrayOfEvents',
  from 'HashRef',
  via { [ SVG::Timeline::Event->new($_) ] },
  from 'ArrayRef[HashRef]',
  via { [ map { SVG::Timeline::Event->new($_) } @$_ ] };

=item * events - a reference to an array containing events. Events are hash
references. See L<add_event> below for the format of events.

=cut

has events => (
  traits  => ['Array'],
  isa     => 'ArrayOfEvents',
  is      => 'rw',
  coerce  => 1,
  default => sub { [] },
  handles => {
    all_events   => 'elements',
    add_event    => 'push',
    count_events => 'count',
    has_events   => 'count',
  },
);

around 'add_event' => sub {
  my $orig = shift;
  my $self = shift;

  $self->_clear_viewbox;
  $self->_clear_svg;

  my $index = $self->count_events + 1;
  $_[0]->{index} = $index;

  $self->$orig(@_);
};

=item * width - the width of the output in any format used by SVG. The default
is 100%.

=cut

has width => (
  is      => 'ro',
  isa     => 'Str',
  default => '100%',
);

=item * height - the height of the output in any format used by SVG. The
default is 100%.

=cut

has height => (
  is      => 'ro',
  isa     => 'Str',
  default => '100%',
);

=item * aspect_ratio - the default is 16/9.

=cut

has aspect_ratio => (
  is => 'ro',
  isa => 'Num',
  default => 16/9,
);

=item * viewport - a viewport definition (which is a space separated list of
four integers. Unless you know what you're doing, it's probably best to leave
the class to work this out for you.

=cut

has viewbox => (
  is         => 'ro',
  isa        => 'Str',
  lazy_build => 1,
  clearer    => '_clear_viewbox',
);

sub _build_viewbox {
  my $self = shift;
  return join ' ',
    $self->min_year * $self->units_per_year,
    0,
    $self->years * $self->units_per_year,
    ($self->bar_height * $self->events_in_timeline) + $self->bar_height
    + (($self->count_events - 1) * $self->bar_height * $self->bar_spacing);
}

=item * svg - an instance of the SVG class that is used to generate the final
SVG output. Unless you're using a subclass of this class for some reason,
there is no reason to set this manually.

=cut

has svg => (
  is         => 'ro',
  isa        => 'SVG',
  lazy_build => 1,
  clearer    => '_clear_svg',
  handles    => [qw[xmlify line text rect cdata]],
);

sub _build_svg {
  my $self = shift;

  $_->{end} //= (localtime)[5] + 1900 foreach $self->all_events;

  return SVG->new(
    width   => $self->width,
    height  => $self->height,
    viewBox => $self->viewbox,
  );
}

=item * default_colour - the colour that is used to fill the timeline
blocks. This should be defined in the RGB format used by SVG. For example,
red would be 'RGB(255,0,0)'.

=cut

has default_colour => (
  is         => 'ro',
  isa        => 'Str',
  lazy_build => 1,
);

sub _build_default_colour {
  return 'rgb(255,127,127)';
}

=item * years_per_grid - the number of years between vertical grid lines
in the output. The default of 10 should be fine unless your timeline covers
a really long timespan.

=cut

# The number of years between vertical grid lines
has years_per_grid => (
  is      => 'ro',
  isa     => 'Int',
  default => 10, # One decade by default
);

=item * bar_height - the height of an individual timeline bar.

=cut

has bar_height => (
  is      => 'ro',
  isa     => 'Int',
  default => 50,
);

=item * bar_spacing - the height if the vertical space between bars (expresssed
as a decimal fraction of the bar height).

=cut

has bar_spacing => (
  is      => 'ro',
  isa     => 'Num',
  default => 0.25,
);

=item * decade_line_colour - the colour of the grid lines.

=cut

has decade_line_colour => (
  is      => 'ro',
  isa     => 'Str',
  default => 'rgb(127,127,127)',
);

=item * bar_outline_colour - the colour that is used for the outline of the
timeline bars.

=cut

has bar_outline_colour => (
  is      => 'ro',
  isa     => 'Str',
  default => 'rgb(0,0,0)',
);

=back

=head2 events_in_timeline

The number of events that we need to make space for in the timeline. This
is generally just the number of events that we have added to the timeline, but
this method is here in case subclasses want t odo something different.

=cut

sub events_in_timeline {
  return $_[0]->count_events;
}

=head2 add_event

Takes a hash reference with event details and adds an L<SVG::Timeline::Event>
to the timeline. The following details are supported:

=over 4

=item * text - the name of the event that is displayed on the bar. This is required.

=item * start - the start year of the event. It is a string of format C<YYYY-MM-DD>.
For example, C<2017-07-02> is the 2nd of July 2017. The month and day can be omitted
(in which case they are replaced with '01').

=item * end - the end year of the event, requirements are the same as that of C<start>.
 
=item * colour - the colour that is used to fill the timeline block. This should be
defined in the RGB format used by SVG. For example, red would be 'RGB(255,0,0)'.
This is optional. If not provided, the C<default_color> is used.

=back

=head2 calculated_height

The height of the timeline in "calculated units".

=cut

sub calculated_height {
  my $self = shift;

  # Number of events ...
  my $calulated_height = $self->events_in_timeline;
  # ... plus one for the header ...
  $calulated_height++;
  # ... multiplied by the bar height...
  $calulated_height *= $self->bar_height;
  # .. add spacing.
  $calulated_height += $self->bar_height * $self->bar_spacing *
                       ($self->events_in_timeline - 1);

  return $calulated_height;
}

=head2 calculated_width

The width in "calulated units".

=cut

sub calculated_width {
  my $self = shift;

  return $self->calculated_height * $self->aspect_ratio;
}

=head2 units_per_year

The number of horizontal units that each year should take up.

=cut

sub units_per_year {
  my $self = shift;

  return $self->calculated_width / $self->years;
}

=head2 draw_grid

Method to draw the underlying grid.

=cut

sub draw_grid{
  my $self = shift;

  my $curr_year = $self->min_year;
  my $units_per_year = $self->units_per_year;

  # Draw the grid lines
  while ( $curr_year <= $self->max_year ) {
    unless ( $curr_year % $self->years_per_grid ) {
      $self->line(
        x1           => $curr_year * $units_per_year,
        y1           => 0,
        x2           => $curr_year * $units_per_year,
        y2           => $self->calculated_height,
        stroke       => $self->decade_line_colour,
        stroke_width => 1
      );
      $self->text(
        x           => ($curr_year + 1) * $units_per_year,
        y           => 20,
        'font-size' => $self->bar_height / 2
      )->cdata($curr_year);
    }
    $curr_year++;
  }

  $self->rect(
     x             => $self->min_year * $units_per_year,
     y             => 0,
     width         => $self->years * $units_per_year,
     height        => ($self->bar_height * ($self->events_in_timeline + 1))
                    + ($self->bar_height * $self->bar_spacing
                       * ($self->events_in_timeline - 1)),
     stroke        => $self->bar_outline_colour,
    'stroke-width' => 1,
    fill           => 'none',
  );

  return $self;
}

=head2 draw

Method to draw the timeline.

=cut

sub draw {
  my $self = shift;
  my %args = @_;

  croak "Can't draw a timeline with no events"
    unless $self->has_events;

  $self->draw_grid;

  my $curr_event_idx = 1;
  foreach ($self->all_events) {

    $_->draw_on($self);

    $curr_event_idx++;
  }

  return $self->xmlify;
}

=head2 min_year

Returns the minimum year from all the events in the timeline.

=cut

sub min_year {
  my $self = shift;
  return unless $self->has_events;
  my @years = map { int ($_->start) } $self->all_events;
  return min(@years);
}

=head2 max_year

Returns the maximum year from all the events in the timeline.

=cut

sub max_year {
  my $self = shift;
  return unless $self->has_events;
  my @years = map { int($_->end) // localtime->year } $self->all_events;
  return max(@years);
}

=head2 years

The number of years that all the events in the timeline span.

=cut

sub years {
  my $self = shift;
  return $self->max_year - $self->min_year;
}

no Moose;
__PACKAGE__->meta->make_immutable;

=head1 AUTHOR

Dave Cross <dave@perlhacks.com>

=head1 COPYRIGHT AND LICENCE

Copyright (c) 2017, Magnum Solutions Ltd. All Rights Reserved.

This library is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1;
