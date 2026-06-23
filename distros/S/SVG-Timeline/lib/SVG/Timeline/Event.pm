=head1 NAME

SVG::Timelime::Event - A single event in an SVG timeline.

=head1 SYNOPSIS

See L<SVG::Timeline>.

=cut

package SVG::Timeline::Event;

use 5.014;

use Moose;
use Moose::Util::TypeConstraints;
use DateTime;
use DateTime::Format::Strptime;

coerce __PACKAGE__,
  from 'HashRef',
  via  { __PACKAGE__->new($_) };

# Chosen format: yyyy-mm-dd
subtype 'SVG::Timeline::DateStr',
  as 'Str',
  where   { m/ \d{4}-\d{2}-\d{2} /ax };

subtype 'SVG::Timeline::YearMonthStr',
  as 'Str',
  where   { m/ \d{4}-\d{2} /ax };

subtype 'SVG::Timeline::YearStr',
  as 'Str',
  where   { m/ \d{4} /as };

subtype 'SVG::Timeline::Num',
  as 'Num';

coerce 'SVG::Timeline::DateStr',
  from 'SVG::Timeline::YearStr',
  via  { $_ . '-01-01' };

coerce 'SVG::Timeline::DateStr',
  from 'SVG::Timeline::YearMonthStr',
  via  { $_ . '-01' };

coerce 'SVG::Timeline::Num',
  from 'SVG::Timeline::DateStr',
  via  \&_str2num;

has index => (
  is => 'ro',
  isa => 'Int',
  required => 1,
);

has text => (
  is => 'ro',
  isa => 'Str',
  required => 1,
);

sub _str2num {
  my ($datestr) = @_;

  my $date = DateTime::Format::Strptime->new( pattern => '%Y-%m-%d' )
               ->parse_datetime($datestr);

  return $date->year + ( $date->day_of_year / ($date->is_leap_year ? 366 : 365) );
}

has start => (
  is => 'ro',
  isa => 'SVG::Timeline::Num',
  required => 1,
  coerce => 1,
);

has end => (
  is => 'ro',
  isa => 'SVG::Timeline::Num',
  required => 1,
  coerce => 1,
);

has colour => (
  is => 'ro',
  isa => 'Maybe[Str]',
  required => 0,
);

=head1 METHODS

=head2 start_year

Return the year that the event started.

=cut

sub start_year {
  my $self = shift;

  return int $self->start;
}

=head2 end_year

Return the year that the event ended.

=cut

sub end_year {
  my $self = shift;

  if ($self->end) {
    return int $self->end;
  } else {
    return DateTime->now->year;
  }
}

=head2 draw_on($tl)

Draw the event inside the given timeline object.

=cut

sub draw_on {
  my $self = shift;
  my ($tl) = @_;

  my $x = $self->start * $tl->units_per_year;
  my $y = ($tl->bar_height * $self->index)
        + ($tl->bar_height * $tl->bar_spacing
           * ($self->index - 1));

  my $width = ($self->end - $self->start) * $tl->units_per_year;

  $tl->rect(
    x              => $x,
    y              => $y,
    width          => $width,
    height         => $tl->bar_height,
    fill           => $self->colour // $tl->default_colour,
    stroke         => $tl->bar_outline_colour,
    'stroke-width' => 1
  );

  my $font_size   = $tl->bar_height * 0.8;
  my $padding     = $tl->bar_height * 0.2;
  my $text_x      = $x + $padding;
  my $text_anchor = 'start';

  # Estimate text width: approximate average character width is 0.6 × font-size
  my $approx_text_width = length($self->text) * $font_size * 0.6;
  my $right_edge        = $x + $width;
  my $image_right_edge  = $tl->max_year * $tl->units_per_year;

  if ($text_x + $approx_text_width > $image_right_edge) {
    $text_x      = ($right_edge < $image_right_edge ? $right_edge : $image_right_edge) - $padding;
    $text_anchor = 'end';
  }

  $tl->text(
    x             => $text_x,
    y             => $y + $font_size,
    'font-size'   => $font_size,
    'text-anchor' => $text_anchor,
  )->cdata($self->text);
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
