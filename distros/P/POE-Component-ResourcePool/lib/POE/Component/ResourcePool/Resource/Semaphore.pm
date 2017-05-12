#!/usr/bin/perl

package POE::Component::ResourcePool::Resource::Semaphore;
use Moose;

with qw(POE::Component::ResourcePool::Resource);

has initial_value => (
	isa => "Num",
	is  => "ro",
	required => 1,
);

has value => (
	isa => "Num",
	is  => "rw",
	writer   => "_value",
	init_arg => undef,
);

sub BUILD {
	my $self = shift;
	$self->_value( $self->initial_value );
}

sub could_allocate {
	my ( $self, $pool, $request, $value ) = @_;

	return ( $value <= $self->initial_value );
}

sub try_allocating {
	my ( $self, $pool, $request, $value ) = @_;

	if ( $value <= $self->value ) {
		return $value;
	} else {
		return;
	}
}

sub finalize_allocation {
	my ( $self, $pool, $request, $value ) = @_;

	$self->_value( $self->value - $value );

	return $value;
}

sub free_allocation {
	my ( $self, $pool, $request, $value ) = @_;

	$self->_value( $self->value + $value );

	$self->notify_all_pools;
}

__PACKAGE__

__END__

=pod

=head1 NAME

POE::Component::ResourcePool::Resource::Semaphore - numerical semaphore resource.

=head1 SYNOPSIS

	# this example will allow up to 10 concurrent URL fetches by blocking
	# sessions until they get their resources allocated.

	# the control could be inverted such that the main loop queues up many
	# requests, each of which creates a fetcher session.

	# the actual URL fetching code has been omitted for brevity.


	# first create the semaphore:
	my $sem = POE::Component::ResourcePool::Resource::Semaphore->new( initial_value => 10 );


	# then add it to a pool:
	my $pool = POE::Component::ResourcePool->new(
		resources => { connections => $sem },
	)


	# finally queue requests that will trigger the callback when they are
	# fulfilled.

	foreach my $url ( @urls ) {
		POE::Session->create(
			inline_states => {
				_start => sub {
					my ( $kernel, $heap ) = @_[KERNEL, HEAP];

					$pool->request(
						params => { connections => 1 },
						event  => "fetch",
					);
				},
				fetch => sub {
					my ( $kernel, $heap ) = @_[KERNEL, HEAP];

					... fetch ...

					$heap->{request}->dismiss;
				},
			},
		);
	}

=head1 DESCRIPTION

This class provides a numerical semaphore based resource for
L<POE::Component::ResourcePool>.

This is useful for throttling resources, for example the number of concurrent
jobs or a symbolic value for memory units.

The semaphore will fulfill requests for numerical values (the default value is
1) as long as it's counter remains above zero.

Requests asking for more than the initial value will fail immediately.

=head1 METHODS

=over 4

=item could_allocate

Returns true if the value is numerically less than or equal to the semaphore's
initial value.

=item try_allocating

Successfully allocates if the value is numerically less than or equal to the
semaphore's current value.

=item finalize_allocation

Finalizes an allocation by deducting the requested value from the semaphore's
current value, and returns the request value as the parameter for the resource.

=item free_allocation

Adds the freed value to the semaphore's current value, and notifies all pools.

Since allocation attempts are a simple procedure no attempt at request tracking
is made, and all pools will be notified unconditionally.

=back

=head1 ATTRIBUTES

=over 4

=item initial_value

The initial value of the semaphore.

Required.

=item value

The current value of the semaphore.

Read only.

=back

=cut
