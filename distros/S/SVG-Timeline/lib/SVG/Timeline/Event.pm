=head1 NAME

SVG::Timelime::Event - A single event in an SVG timeline.

=head1 SYNOPSIS

See L<SVG::Timeline>.

=cut

package SVG::Timeline::Event;

use 5.010;

use Moose;
use Moose::Util::TypeConstraints;

coerce __PACKAGE__,
  from 'HashRef',
  via  { __PACKAGE__->new($_) };

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

has start => (
  is => 'ro',
  isa => 'Int',
  required => 1,
);

has end => (
  is => 'ro',
  isa => 'Int',
  required => 1,
);

has colour => (
  is => 'ro',
  isa => 'Maybe[Str]',
  required => 0,
);

=head1 METHODS

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

  $tl->rect(
    x              => $x,
    y              => $y,
    width          => ($self->end - $self->start) * $tl->units_per_year,
    height         => $tl->bar_height,
    fill           => $self->colour // $tl->default_colour,
    stroke         => $tl->bar_outline_colour,
    'stroke-width' => 1
  );

  $tl->text(
    x => ($x + $tl->bar_height * 0.2),
    y => $y + $tl->bar_height * 0.8,
    'font-size' => $tl->bar_height * 0.8,
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
