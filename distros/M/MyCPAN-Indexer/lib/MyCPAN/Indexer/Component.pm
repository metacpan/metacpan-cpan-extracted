package MyCPAN::Indexer::Component;
use strict;
use warnings;

use vars qw($VERSION);

use Carp         qw( croak );
use Scalar::Util qw( weaken );

$VERSION = '1.282';

=encoding utf8

=head1 NAME

MyCPAN::Indexer::Component - base class for MyCPAN components

=head1 SYNOPSIS

	package MyCPAN::Indexer::NewComponent;

	use base qw(MyCPAN::Indexer::Component);

	sub component_type { $_[0]->reporter_type }

=head1 DESCRIPTION

This module implements features common to all C<MyCPAN::Indexer>
components. Each component is able to communicate with a coordinator
object to find out the results and notes left by other components.
Most of that delegation infrastructure is hidden since each component
can call methods on its own instances that this module dispatches
appropriately.

=cut

=head2 Methods

=over 4

=item new( [COORDINATOR] )

Create a new component object. This is mostly to have a place to
store a reference to the coordinator object. See C<get_coordinator>.

=cut

sub component_type { croak "Component classes must implement component_type" }

sub new
	{
	my( $class, $coordinator ) = @_;

	my $self = bless {}, $class;

	if( defined $coordinator )
		{
		$self->set_coordinator( $coordinator );
		$coordinator->set_note( $self->component_type, $self );
		}

	$self;
	}

=item get_coordinator

Get the coordinator object. This is the object that coordinates all of the
components. Each component communicates with the coordinator and other
components can see it.

=cut

sub get_coordinator { $_[0]->{_coordinator} }

=item set_coordinator( $coordinator )

Set the coordinator object. C<new> already does this for you if you pass it a
coordinator object. Each component expects the cooridnator object to respond
to these methods:

	get_info
	set_info
	get_note
	set_note
	get_config
	set_config
	increment_note
	decrement_note
	push_onto_note
	unshift_onto_note
	get_note_list_element
	set_note_unless_defined

=cut

BEGIN {

my @methods_to_dispatch_to_coordinator = qw(
	get_info
	set_info
	get_note
	set_note
	get_config
	set_config
	get_component
	increment_note
	decrement_note
	push_onto_note
	unshift_onto_note
	get_note_list_element
	set_note_unless_defined
	);

foreach my $method ( @methods_to_dispatch_to_coordinator )
	{
	no strict 'refs';
	*{$method} = sub {
		my $self = shift;
		$self->get_coordinator->$method( @_ );
		}
	}

sub set_coordinator
	{
	my( $self, $coordinator ) = @_;

	my @missing = grep { ! $coordinator->can( $_ ) }
		@methods_to_dispatch_to_coordinator;

	croak "Coordinator object is missing these methods: @missing"
		if @missing;

	$self->{_coordinator} = $coordinator;

	weaken( $self->{_coordinator} );

	return $self->{_coordinator};
	}

}

=item null_type

=item collator_type

=item dispatcher_type

=item indexer_type

=item interface_type

=item queue_type

=item reporter_type

=item worker_type

Returns the magic number that identifies the component type. You shouldn't
ever have to look at the particular number. Some components might have
several types.

=cut

sub null_type       { 0 }
sub collator_type   { 0b00000001 }
sub dispatcher_type { 0b00000010 }
sub indexer_type    { 0b00000100 }
sub interface_type  { 0b00001000 }
sub queue_type      { 0b00010000 }
sub reporter_type   { 0b00100000 }
sub worker_type     { 0b01000000 }

=item combine_types( TYPES )

For components that implement several roles, create a composite type:

	my $custom_type = $self->combine_types(
		map { $self->$_() } qw( queue_type worker_type );
		}

If you want to test that value, use the C<is_type> methods.

=cut

sub combine_types
	{
	my( $self, @types ) = @_;

	my $combined_type = 0;

	foreach my $type ( @types )
		{
		$combined_type |= $type;
		}

	return $combined_type;
	}

=item is_type( CONCRETE, TEST )

Tests a CONCRETE type (the one a component claims to be) with the TYPE
that you want to check. This is the general test.

=cut

sub is_type { $_[1] & $_[2]	}

=item is_null_type

=item is_collator_type

=item is_dispatcher_type

=item is_indexer_type

=item is_interface_type

=item is_queue_type

=item is_reporter_type

=item is_worker_type

These are curried versions of C<is_type>. They should be a bit easier to use.

=cut

sub is_null_type       { $_[1] == 0 }
sub is_collator_type   { $_[0]->is_type( $_[1], $_[0]->collator_type   ) }
sub is_dispatcher_type { $_[0]->is_type( $_[1], $_[0]->dispatcher_type ) }
sub is_indexer_type    { $_[0]->is_type( $_[1], $_[0]->indexer_type    ) }
sub is_interface_type  { $_[0]->is_type( $_[1], $_[0]->interface_type  ) }
sub is_queue_type      { $_[0]->is_type( $_[1], $_[0]->queue_type      ) }
sub is_reporter_type   { $_[0]->is_type( $_[1], $_[0]->reporter_type   ) }
sub is_worker_type     { $_[0]->is_type( $_[1], $_[0]->worker_type     ) }

=back

=head1 SOURCE AVAILABILITY

This code is in Github:

	git://github.com/briandfoy/mycpan-indexer.git

=head1 AUTHOR

brian d foy, C<< <bdfoy@cpan.org> >>

=head1 COPYRIGHT AND LICENSE

Copyright © 2008-2018, brian d foy <bdfoy@cpan.org>. All rights reserved.

You may redistribute this under the terms of the Artistic License 2.0.

=cut

1;
