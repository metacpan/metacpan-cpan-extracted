package Osgood::EventList;
use Moose;
use MooseX::AttributeHelpers;
use MooseX::Iterator;
use MooseX::Storage;

with Storage('format' => 'JSON', 'io' => 'File');

has 'events' => (
    metaclass => 'Collection::Array',
    is => 'rw',
    isa => 'ArrayRef',
    default => sub { [] },
    provides => {
        push => 'add_to_events',
        count => 'size'
    }
);

has 'iterator' => (
    metaclass => 'Iterable',
    iterate_over => 'events'
);

=head1 NAME

Osgood::EventList - A list of Osgood events.

=head1 DESCRIPTION

A list of events.

=head1 SYNOPSIS

  my $list = Osgood::EventList->new;
  $list->add_to_events($event);
  print $list->size."\n";

=head1 METHODS

=head2 Constructor

=head2 new

Creates a new Osgood::EventList object.

=head2 add_to_events

Add the specified event to the list.

=head2 events

Set/Get the ArrayRef of events in this list.

=head2 iterator

Returns a MooseX::Iterator for iterating over events.

=head2 size

Returns the number of events in this list.

=head2 get_highest_id

Retrieves the largest id from the list of events.  This is useful for keeping
state with an external process that needs to 'remember' the last event id
it handled.

=cut
sub get_highest_id {
	my ($self) = @_;

	my $high = undef;
	foreach my $event (@{ $self->events }) {
		if(!defined($high) || ($high < $event->id)) {
			$high = $event->id;
		}
	}

	return $high;
}

=head1 AUTHOR

Cory 'G' Watson <gphat@cpan.org>

=head1 SEE ALSO

perl(1), L<Osgood::Event>

=head1 COPYRIGHT AND LICENSE

Copyright 2008-2009 by Magazines.com, LLC

You can redistribute and/or modify this code under the same terms as Perl
itself.

=cut

__PACKAGE__->meta->make_immutable;

1;