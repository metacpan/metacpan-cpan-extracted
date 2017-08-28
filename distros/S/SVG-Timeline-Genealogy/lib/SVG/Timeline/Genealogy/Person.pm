=head1 NAME

SVG::Timeline::Genealogical::Person - a single person in a genealogical timeline

=head1 SYNOPSIS

See L<SVG::Timeline::Genealogical>.

=cut

package SVG::Timeline::Genealogy::Person;

use Moose;
extends 'SVG::Timeline::Event';

use Moose::Util::TypeConstraints;

use Genealogy::Ahnentafel ();

coerce __PACKAGE__,
  from 'HashRef',
  via  { __PACKAGE__->new($_) };

has ahnen => (
  is => 'ro',
  isa => 'Int',
);

has +end => (
  is => 'ro',
  isa => 'Int',
  required => 0,
);

has generation => (
  is => 'ro',
  isa => 'Int',
  lazy_build => 1,
);

sub _build_generation {
  my $self = shift;
  return Genealogy::Ahnentafel->new({
    ahnentafel => $self->ahnen,
  })->generation;
}

# Array of colours - one for each generation.
has colours => (
  is         => 'ro',
  isa        => 'ArrayRef',
  lazy_build => 1,
);

sub _build_colours {
  no warnings 'qw';    # I know what I'm doing here!
  return [
    map { "rgb($_)" }
      qw(
      0
      255,127,127
      127,255,127
      127,127,255
      255,255,127
      255,127,255
      127,255,255
      )
  ];
}

has +colour => (
  is => 'ro',
  isa => 'Str',
  lazy_build => 1,
);

sub _build_colour {
  my $self = shift;
  return $self->colours->[$self->generation];
}

=head1 METHODS AND ATTRIBUTES

=head2 BUILD

Called by Moose after the construction of a new object. This just updates
the C<text> attribute to add the years of the person's birth and death.

=cut

sub BUILD {
  my $self = shift;

  my $text = $self->{text};

  if ($self->start) {
    $text .= ' (' . $self->start . ' - ';
    $text .= $self->end if $self->end;
    $text .= ')';
  }

  $self->{text} = $text;
}

=head2 set_index

Called by SVG::Timeline::Genealogical each time a new person is added to the
timeline, this method works out where this person should appear in the
timeline.

=cut

sub set_index {
  my $self = shift;
  my ($count_of_people) = @_;

  my $den = 2 ** $self->generation;
  my $num = 2 * ($self->ahnen - $den / 2) + 1;

  my $index = $count_of_people * ($num/$den);

  $self->{index} = $index;
}

=head1 AUTHOR

Dave Cross <dave@perlhacks.com>

=head1 COPYRIGHT AND LICENCE

Copyright (c) 2017, Magnum Solutions Ltd. All Rights Reserved.

This library is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1;
