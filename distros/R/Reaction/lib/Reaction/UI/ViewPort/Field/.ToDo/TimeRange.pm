package Reaction::UI::ViewPort::Field::TimeRange;

use Reaction::Class;
use Reaction::Types::DateTime;
use DateTime;
use DateTime::SpanSet;
use Time::ParseDate ();

use namespace::clean -except => [ qw(meta) ];
extends 'Reaction::UI::ViewPort::InterfaceModel::Field';



has '+value' => (isa => 'DateTime::SpanSet');

#has '+layout' => (default => 'timerange');

has value_string =>
  (isa => 'Str',  is => 'rw', lazy_fail => 1, trigger_adopt('value_string'));

has delete_label => (
  isa => 'Str', is => 'rw', required => 1, default => sub { 'Delete' },
);

has parent => (
  isa => 'Reaction::UI::ViewPort::TimeRangeCollection',
  is => 'ro',
  required => 1,
  weak_ref => 1
);
sub _build_value_string {
  my $self = shift;
  #return '' unless $self->has_value;
  #return $self->value_string;
};
sub value_array {
  my $self = shift;
  return split(',', $self->value_string);
};
sub adopt_value_string {
  my ($self) = @_;
  my @values = $self->value_array;
  for my $idx (0 .. 3) { # last value is repeat
    if (length $values[$idx]) {
      my ($epoch) = Time::ParseDate::parsedate($values[$idx], UK => 1);
      $values[$idx] = DateTime->from_epoch( epoch => $epoch );
    }
  }
  $self->value($self->range_to_spanset(@values));
};
sub range_to_spanset {
  my ($self, $time_from, $time_to, $repeat_from, $repeat_to, $pattern) = @_;
  my $spanset = DateTime::SpanSet->empty_set;
  if (!$pattern || $pattern eq 'none') {
    my $span = DateTime::Span->from_datetimes(
                 start => $time_from, end => $time_to
               );
    $spanset = $spanset->union( $span );
  } else {
    my $duration = $time_to - $time_from;
    my %args = ( days => $time_from->day + 2,
                hours => $time_from->hour,
              minutes => $time_from->minute,
              seconds => $time_from->second );

    delete $args{'days'} if ($pattern eq 'daily');
    delete @args{qw/hours days/} if ($pattern eq 'hourly');
    $args{'days'} = $time_from->day if ($pattern eq 'monthly');
    my $start_set = DateTime::Event::Recurrence->$pattern( %args );
    my $iter = $start_set->iterator( start => $repeat_from, end => $repeat_to );
    while ( my $dt = $iter->next ) {
      my $endtime = $dt + $duration;
      my $new_span = DateTime::Span->from_datetimes(
                       start => $dt,
                       end => $endtime
                     );
      $spanset = $spanset->union( $new_span );
    }
  }
  return $spanset;
};
sub delete {
  my ($self) = @_;
  $self->parent->remove_range_vp($self);
};

override accept_events => sub { ('value_string', 'delete', super()) };

__PACKAGE__->meta->make_immutable;


1;

=head1 NAME

Reaction::UI::ViewPort::Field::TimeRange

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 METHODS

=head2 value

  Accessor for a L<DateTime::SpanSet> object.

=head2 value_string

  Returns: Encoded range string representing the value.

=head2 value_array

  Returns: Arrayref of the elements of C<value_string>.

=head2 parent

  L<Reaction::UI::ViewPort::TimeRangeCollection> object.

=head2 range_to_spanset

  Arguments: $self, $time_from, $time_to, $repeat_from, $repeat_to, $pattern
  where $time_from, $time_to, $repeat_from, $repeat_to are L<DateTime>
  objects, and $pattern is a L<DateTime::Event::Recurrence> method name

  Returns: $spanset

=head2 delete

  Removes TimeRange from C<parent> collection.

=head2 delete_label

  Label for the delete option. Default: 'Delete'.

=head1 SEE ALSO

=head2 L<Reaction::UI::ViewPort::Field>

=head2 L<Reaction::UI::ViewPort::TimeRangeCollection>

=head1 AUTHORS

See L<Reaction::Class> for authors.

=head1 LICENSE

See L<Reaction::Class> for the license.

=cut
