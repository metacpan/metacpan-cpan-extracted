#!/usr/bin/perl

package POE::Component::ResourcePool::Resource;
use Moose::Role;

use Set::Object::Weak;

#use MooseX::Types::Set::Object;

sub could_allocate {
	my ( $self, $pool, $request ) = @_;

	return 1;
}

requires "try_allocating";

requires "finalize_allocation";

requires "free_allocation";

sub forget_request {
	my ( $self, $pool, $request ) = @_;

	return;
}

sub register_request {
	my ( $self, $pool, $request ) = @_;

	return;
}

sub notify_all_pools {
	my $self = shift;
	$_->resource_updated($self) for $self->registered_pools;
}

has _registered_pools => (
	#isa => "Set::Object",
	is  => "ro",
	init_arg => undef,
	default  => sub { Set::Object::Weak->new },
	handles => {
		registered_pools => "members",
		register_pool    => "insert",
		unregister_pool  => "remove",
	}
);

__PACKAGE__;

__END__

=pod

=head1 NAME

POE::Component::ResourcePool::Resource - base role for resources.

=head1 SYNOPSIS

	package MyResource;
	use Moose;

	with qw(POE::Component::ResourcePool::Resource);

	sub could_allocate {
		my ( $self, $pool, $request, $value ) = @_;

		if ( $self->could_never_allocate($value) ) {
			return;
		} else {
			return 1;
		}
	}

	sub try_allocating {
		my ( $self, $pool, $request, $value ) = @_;

		if ( $self->can_allocate_right_now($value) ) {
			return @allocation; # anything, but usually $value
		} else {
			return; # empty list denotes failure
		}
	}

	sub finalize_allocation {
		my ( $self, $pool, $request, @allocation ) = @_;

		...

		return $param; # the actual parameter to be given back to the resource
	}

	sub free_allocation {
		my ( $self, $pool, $request, @allocation ) = @_;

	}

=head1 DESCRIPTION

This role provides an API for abstract asynchroneous resource allocation.

Resource allocation is performed via a two step process, the first step is to
attempt allocation noncomittally, and the second is to finalize an allocation.

Finalization is guaranteed to happen atomically with respect to allocation
attempts, for a given resource, but if allocation of another resource fails
then the request will not finalize the allocation.

All the values involved are completely arbitrary, but they are managed by the
resource pool in order to relief resources of the task of tracking requests and
their allocations themselves.

=head1 METHODS

=over 4

=item could_allocate $pool, $request, $value

Check if the C<$value> specified in the given C<$request> object could ever be
allocated.

The default implementation will return true.

The purpose of this method is to allow unfulfillable resources to generate an
error when they are queued.

For example a request that tries to allocate a value from a semaphore resource,
that is bigger than the semaphore's initial value should return an error.

=item try_allocating $pool, $request, $value

This method should return a non empty list (typically the $value) if $value can
be presently allocated.

The list will only ever be used to pass back into C<finalize_allocation> and
C<free_allocation>, and nothing else, so it is considered effectively private
to the resource.

For an example of why allocation data structures are private see
L<POE::Component::ResourcePool::Resource::TryList> (it needs to keep track of
which resource the allocation was delegated too, for instance).

=item finalize_allocation $request, @allocation

Denotes that the allocation that has previously been successfully tried should
be comitted to the resource and made final.

This is assumed to never fail.

The return value is passed as a parameter to the request, and not used for
anything else.

=item free_allocation $pool, $request, @allocation

Frees an allocation that has been previously finalized.

This method should notify all registered pools if subsequently failed
allocations could now succeed. Even the pool which has freed the allocation
does not assume new allocations may be attempted yet.

Calling C<notify_all_pools> should suffice.

=item notify_all_pools

A convenience method that will call C<resource_updated> for every pool in the
C<registered_pools> list.

=item registered_pools

Returns the list of registered pools, as maintained by C<register_pool> and
C<unregister_pool>.

No order guarantees are provided, but this may change in the if prioritization
is introduced.

This list should be used to send update notifications when the resource is
updated.

=item register_pool $pool

=item unregister_pool $pool

Keep track of pools that are using this resource.

The default implementation uses a wek L<Set::Object> internally.

It is reccomended you do not override this implementation, because in the
future the API may be extended to allow prioritization of pools.

=item register_request $pool, $request

=item forget_request $pool, $request

These are advisory methods that inform the resource when a request starts and
stops becoming relevant to it.

In order to optimize resource update notifications, especially when updates are
continual, a resource may choose to keep track of previously attempted values
weakly indexed by the request that asked for them (in C<try_allocating>).

If the request is canceled or fulfilled (possibly by some other resource) the
pool will notify all involved resources that they can remove it from their data
structures.

The base implementation is a noop, as no tracking is provided by default.

See the L<POE::Component::ResourcePool::Resource::TokenBucket> resource for an
example of how to use this (it notifies based on delays).

=back

=cut

