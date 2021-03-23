=head1 NAME

SVG::Timeline::Genealogy - Create genealogical timelines in SVG

=head1 SYNOPSIS

    use SVG::Timeline::Genealogy

    my $tl = SVG::Timeline::Genealogy->new;

    $tl->add_person({
      ahnen => 1,
      start => 1975,
      text  => 'You',
    });

    $tl->add_person({
      anhen => 2,
      start => 1950,
      end   => 1980,
      text  => 'Your Father',
    });

    $tl->add_person({
      anhen => 3,
      start => 1950,
      text  => 'Your Mother',
    });

    print $tl->draw;

=head1 DESC

This module allows you to easily create SVG documents that represent
genealogical timelines.

The module is a subclass of L<SVG::Timeline> and this documentation should
be read in conjunction with the documentation for that module. SVG::Timeline
deals with events, in this subclass, events have been renamed to people.

When I say "genealogical timeline", I mean an ancestor chart. This is a
diagram which shows the ancestors of a person. Each person on the timeline
is represented by a bar which shows the years they were alive. The position
and colour of the bars show the relationships between the people in the
timeline.

In this module, people have all of the same attributes as events do in
SVG::Timeline, but there is one extra attribute (called "ahnen") which might
need some explanation.

The term "ahnen" is short for "Anhnentafel Number". This is a number that can
be given to people in a genealogical system in order to represent relationships
between them.

If you have the Ahnentafel number of 1, then your father is 2 and mour
mother is 3. You father's parents are 4 and 5 and your mother's are 6 and 7.
These numbers have some interesting properties. If a person's number is C<$x>,
then their father will be C<2 * $x> and their mother will be C<2 * $x + 1>.
Also, this the exception of person 1 (who can be of either sex), all men have
even Ahnentafel numbers and all women have odd ones.

All of which means that if you give us the Ahnentafel number for the people
you add to the chart (and you have to - it's a required attribute), then we
can work out all the relationships between the people.

=cut

package SVG::Timeline::Genealogy;

use 5.010;

our $VERSION = '0.0.5';

use Moose;
use Moose::Util::TypeConstraints;
extends 'SVG::Timeline';

use Time::Piece;
use List::Util 'max';
use SVG::Timeline::Genealogy::Person;

subtype 'ArrayOfPeople', as 'ArrayRef[SVG::Timeline::Genealogy::Person]';

coerce 'ArrayOfPeople',
  from 'HashRef',
  via { [ SVG::Timeline::Genealogy::Person->new($_) ] },
  from 'ArrayRef[HashRef]',
  via { [ map { SVG::Timeline::Genealogy::Person->new($_) } @$_ ] };

has +events => (
  isa => 'ArrayOfPeople',
  is  => 'rw',
  default => sub { [] },
  coerce => 1,
  traits  => ['Array'],
  handles => {
    all_people   => 'elements',
    add_person   => 'push',
    count_people => 'count',
    has_people   => 'count',
  },
);

around 'add_person' => sub {
  my $orig = shift;
  my $self = shift;

  $_[0]->{index} = 0;

  $self->$orig(@_);

  $self->calculate_indexes;
};

=head1 METHODS AND ATTRIBUTES

You'll also need to see the documentation for L<SVG::Timeline>. This document
only includes details of the changed and extra methods and attributes.

=head2 calculate_indexes()

The order that people appear in the chart isn't controlled by the order that
they are added but, rather, their Ahnentafel number. That means that every
time a new person is added, the indexes need to be recalculated. This method
does that. You should never need to call it.

=cut

sub calculate_indexes {
  my $self = shift;

  my $count_of_people = $self->events_in_timeline;

  for ($self->all_people) {
    $_->set_index($count_of_people);
  }
}

=head2 max_generation

Returns the maximum number of generations that the timeline contains.

=cut

sub max_generation {
  my $self = shift;

  return max(map { $_->generation } $self->all_people);
}

=head2 events_in_timeline

Returns the number of events expected in the timeline. This isn't just the
number of events (i.e. people) that have been added to the timeline. In
genealogy, we often don't know some of our ancestry (children being born out
of wedlock is far more common than you might think) and we need to leave space
for those people or the chart will look wrong.

So we calculate the number of expected people from the number of generations
in the timeline.

=cut

sub events_in_timeline {
  my $self = shift;

  return 2 ** $self->max_generation - 1;
}

override 'max_year' => sub {
  return super() // localtime->year;
};

=head1 AUTHOR

Dave Cross <dave@perlhacks.com>

=head1 COPYRIGHT AND LICENCE

Copyright (c) 2017, Magnum Solutions Ltd. All Rights Reserved.

This library is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut


1;
