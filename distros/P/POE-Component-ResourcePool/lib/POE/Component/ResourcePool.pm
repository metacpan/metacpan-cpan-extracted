#!/usr/bin/perl

package POE::Component::ResourcePool;
use MooseX::POE;

use Carp::Clan qr/^(?:POE::Component::ResourcePool|Moose|Class::MOP)/;

use Tie::RefHash;
use Tie::RefHash::Weak;

#use MooseX::Types::Set::Object;

our $VERSION = "0.04";

# nested pools?
# with qw(POE::Component::ResourcePool::Resource);

use POE::Component::ResourcePool::Resource; # load type constraint

use POE::Component::ResourcePool::Request;

with qw(MooseX::POE::Aliased);

sub spawn { shift->new(@_) }

has resources => (
	isa => "HashRef[POE::Component::ResourcePool::Resource]",
	is  => "ro",
	required => 1,
);

has weak_queue => (
	isa => "Bool",
	is  => "ro",
	default => 0,
);

has refcount_pending => (
	isa => "Bool",
	is  => "ro",
	default => 1,
);

has refcount_allocated => (
	isa => "Bool",
	is  => "ro",
	default => 0,
);

sub BUILD {
	my $self = shift;

	$self->MooseX::POE::Aliased::BUILD(@_);

	foreach my $resource ( values %{ $self->resources } ) {
		$resource->register_pool($self);
	}
}

sub DEMOLISH {
	my $self = shift;

	# the extra checks are because in global destruction these values are
	# sometimes already gone
	foreach my $resource ( grep { defined } values %{ $self->resources || return } ) {
		$resource->unregister_pool($self);
	}
}

has request_class => (
	isa => "ClassName",
	is  => "rw",
	default => "POE::Component::ResourcePool::Request",
);

has params => (
	isa => "HashRef[HashRef]",
	is  => "ro",
	init_arg => undef,
	default => sub { Tie::RefHash::Weak::fieldhash my %h },
);

sub request {
	my ( $self, @args ) = @_;

	my $request = @args == 1 ? $args[0] : $self->create_request( @args );

	$self->queue($request);

	return $request;
}

sub create_request {
	my ( $self, @args ) = @_;

	$self->construct_request( pool => $self, @args );
}

sub construct_request {
	my ( $self, @args ) = @_;

	$self->request_class->new( @args );
}

sub dismiss {
	my ( $self, $request ) = @_;

	$request->_dismissed(1);

	$self->_remove_from_queue($request);

	$self->_free_allocations($request);
}

sub queue {
	my ( $self, $request ) = @_;

	$self->_queue_request($request);

	$poe_kernel->refcount_increment( $request->session_id, __PACKAGE__ . "::pending_requests" ) if $self->refcount_pending;

	$self->yield( new_request => $request );
}

sub resource_updated {
	my ( $self, $resource, @requests ) = @_;

	unless ( @requests ) {
		@requests = $self->_requests_by_resource->{$resource}->members;
	}

	my @ready = $self->_unblock_resource( $resource, @requests );

	$self->call( requests_ready => @ready );
}

sub pending_requests {
	my ( $self, $resource ) = @_;

	if ( $resource ) {
		$resource = $self->resources->{$resource} unless ref $resource;
		return $self->_requests_for_resource($resource)->members;
	} else {
		return keys %{ $self->_resources_by_request };
	}
}

sub allocated_requests {
	my ( $self, $resource ) = @_;

	if ( $resource ) {
		my $resources = $self->resources;

		my $resource_name = ref $resource
			? (grep { $resources->{$_} == $resource } keys %$resources )[0]
			: $resource;

		my $allocations = $self->_allocations;

		return grep { exists $allocations->{$_}{$resource_name} } keys %$allocations;
	} else {
		return keys %{ $self->_allocations };
	}
}

sub all_requests {
	my ( $self, @args ) = @_;

	return (
		$self->pending_requests(@args),
		$self->allocated_requests(@args),
	)
}

sub shutdown { shift->clear_alias }

# keyed by request
has _allocations => (
	isa => "HashRef[HashRef[ArrayRef]]",
	is  => "ro",
	init_arg => undef,
	default => sub { Tie::RefHash::Weak::fieldhash my %h },
);


# these attributes and methods implement the qeueue
has _requests_by_resource => (
	#isa => "HashRef[Set::Object[POE::Component::ResourcePool::Request]]",
	is  => "ro",
	init_arg => undef,
	default  => sub { tie my %h, 'Tie::RefHash'; \%h },
);

has _resources_by_request => (
	#isa => "HashRef[HashRef[Set::Object[POE::Component::ResourcePool::Resource]]]",
	is  => "ro",
	init_arg => undef,
	lazy_build => 1,
);

sub _build__resources_by_request {
	my $self = shift;

	tie my %h, $self->weak_queue ? "Tie::RefHash:Weak" : "Tie::RefHash";

	return \%h;
}

sub _queue_request {
	my ( $self, $request ) = @_;

	$self->_validate_request_params($request);

	my $resources = $self->resources;

	my %resources = map { $_ => $resources->{$_} } keys %{ $request->params };

	foreach my $set ( @{ $self->_requests_by_resource }{ values %resources } ) {
		$set ||= Set::Object::Weak->new;
		$set->insert($request);
	}

	$self->_resources_by_request->{$request} = {
		blocked => Set::Object->new(),
		ready   => Set::Object->new( values %resources ),
	};

	foreach my $resource_name ( keys %resources ) {
		$resources{$resource_name}->register_request( $self, $request, $request->params->{$resource_name} );
	}
}

sub _remove_from_queue {
	my ( $self, $request ) = @_;

	return unless exists $self->_resources_by_request->{$request};

	$poe_kernel->refcount_decrement( $request->session_id, __PACKAGE__ . "::pending_requests" ) if $self->refcount_pending;

	my @resources = $self->_all_resources_for_request($request);

	$_->forget_request($self, $request) for @resources;

	foreach my $set ( @{ $self->_requests_by_resource }{ @resources } ) {
		$set->remove($request);
	}

	delete $self->_resources_by_request->{$request};
}

sub _requests_for_resource {
	my ( $self, $resource ) = @_;

	$self->_requests_by_resource->{$resource};
}

sub _resource_sets_for_request {
	my ( $self, $request ) = @_;

	@{ $self->_resources_by_request->{$request} || return }{qw(ready blocked)}
}

sub _blocked_resources_for_request {
	my ( $self, $request ) = @_;

	$self->_resources_by_request->{$request}{blocked};
}

sub _all_resources_for_request {
	my ( $self, $request ) = @_;

	map { $_->members } grep { defined } $self->_resource_sets_for_request($request);
}

sub _unblock_resource {
	my ( $self, $resource, @requests ) = @_;

	my @ret;

	foreach my $request ( @requests ) {
		my ( $ready, $blocked ) = $self->_resource_sets_for_request($request);

		if ( $blocked->remove($resource) ) {
			$ready->insert($resource);
			push @ret, $request if $blocked->is_null;
		}
	}

	return @ret;
}

sub _block_resource {
	my ( $self, $resource, @requests ) = @_;

	foreach my $request ( @requests ) {
		my ( $ready, $blocked ) = $self->_resource_sets_for_request($request);

		$ready->remove($resource) and $blocked->insert($resource);
	}
}

# end of queue methods



sub _validate_request_params {
	my ( $self, $request ) = @_;

	my $params = $request->params;
	my $resources = $self->resources;

	if ( my @missing = grep { not exists $resources->{$_} } keys %$params ) {
		croak "request $request has parameters for which no resource can be found: " . join ", ", @missing;
	}

	my @failed;
	foreach my $name ( keys %$params ) {
		my $resource = $resources->{$name};

		unless ( $resource->could_allocate( $self, $request, $params->{$name} ) ) {
			push @failed, $name;
		}
	}

	if ( @failed ) {
		croak "The following resources rejected $request: " . join  ", ", @failed;
	}
}

event new_request => sub {
	my ( $self, $request ) = @_[OBJECT, ARG0 .. $#_];

	$self->_try_allocating($request);
};

event requests_ready => sub {
	my ( $self, @requests ) = @_[OBJECT, ARG0 .. $#_];

	foreach my $req ( @requests ) {
		$self->_try_allocating($req);
	}
};


sub _free_allocations {
	my ( $self, $request ) = @_;

	$poe_kernel->refcount_decrement( $request->session_id, __PACKAGE__ . "::allocated_requests" ) if $self->refcount_allocated;

	my $allocations = delete $self->_allocations->{$request} || return;

	my $resources = $self->resources;

	foreach my $name ( keys %$allocations ) {
		$resources->{$name}->free_allocation( $self, $request, @{ $allocations->{$name} } );
	}
}

sub _try_allocating {
	my ( $self, $request ) = @_;

	return if $request->fulfilled;

	my $blocked = $self->_blocked_resources_for_request($request);

	return unless $blocked->is_null; # can't allocate if there are blocking resources

	my $resources = $self->resources;

	my $params = $request->params;

	my %allocations;

	# attempt to allocate the value from each resource
	foreach my $resource_name ( keys %$params ) {
		my $res_params = $params->{$resource_name};

		my $resource = $resources->{$resource_name};

		my @allocation = $resource->try_allocating( $self, $request, $params->{$resource_name} );

		if ( @allocation ) {
			$allocations{$resource_name} = \@allocation;
		} else {
			$self->_block_resource($resource, $request);
		}
	}

	# if no allocations failed then the blocked set is still empty
	return unless $blocked->is_null;

	$poe_kernel->refcount_increment( $request->session_id, __PACKAGE__ . "::finalizing_allocation" );

	$poe_kernel->refcount_increment( $request->session_id, __PACKAGE__ . "::allocated_requests" ) if $self->refcount_allocated;

	# the item can now be removed from the queue, and dispatched
	$self->_remove_from_queue($request);

	$request->_fulfilled(1);

	$self->_allocations->{$request} = \%allocations;

	my %output_params;

	foreach my $resource_name ( keys %$params ) {
		my $resource = $resources->{$resource_name};
		$output_params{$resource_name} = $resource->finalize_allocation( $self, $request, @{ $allocations{$resource_name} } );
	}

	$request->_results(\%output_params);

	$request->invoke_callback( pool => $self, %output_params );

	$poe_kernel->refcount_decrement( $request->session_id, __PACKAGE__ . "::finalizing_allocation" );

	return $request;
}

no MooseX::POE;

__PACKAGE__

__END__

=pod

=head1 NAME

POE::Component::ResourcePool - Asynchronous generic resource management for POE
based apps.

=head1 SYNOPSIS

	my $resource = POE::Component::ResourcePool::Resource::Blah->new( ... );

	my $pool = POE::Component::ResourcePool->new(
		resources => {
			moose => $resource,
			elk   => ...,
			cow   => ...,
		},
	);

	# ... in some session somewhere:

	$pool->request(
		params => {
			moose => ..., # arbitrary params for Blah type resources
			elk   => ...,
		},
		event => "got_it", # dispatched when both moose and elk can be allocated at the same time
	);

=head1 DESCRIPTION

This resource pool object provides very flexible resource management for POE
based apps.

A pool consists of any number of named, abstract resources to be shared amongst
several tasks.

Requests for resources can contain arbitrary parameters and are fulfilled with
arbitrary values.

The pool will manage resources, sharing them between requests as they become
available.

Using a simple interface one can easily write arbitrary resource abstractions,
which are potentially affected by outside mechanisms (for example the token
bucket resource allows time based throttling).

=head1 QUEUE ALGORITHM

The request queue works by maintaining a set of ready and blocked resources for
each request.

Whenever all the resources for a given request are ready the pool will attempt
to allocate the request.

If any resource failed to allocate the parameter specified for it in the
request, it is marked as blocked for that request.

If all resources succeeded the allocations are finalized, the request callback
is invoked and the request is removed from the queue.

Whenever a resource signals that it's been updated (for example if its
allocation has been freed, or if some other POE event changed it) it will be
marked as ready for allocation in the queue again.

=head1 REFERENCE MANAGEMENT

Based on the values of C<refcount_allocated> (defaults to false) and
C<refcount_pending> (defaults to true) the resource pool will increment the
reference count of sessions that have created requests and decrement it when
the resource is fulfilled.

This is because typically a session is not doing anything, and as such has no
resources/events associated with it while it waits for a resource.

Once the resource is allocated the session will probably have at least one more
event (depending on the callback), and will continue working until it's done,
at which point the kernel will garbage collect it.

This default behavior allows you to simply keep your requests on the heap so
that when the session closes automatically fulfilled requests will be freed.

Setting C<refcount_allocated> will cause the session to remain alive until the
resource is dismissed (whether manually or due to C<DESTROY>). Note that if
C<refcount_allocated> is true and the resource is kept on the heap a circular
reference is caused and the session will leak unless the resource is explicitly
dismissed.

Setting C<refcount_pending> to a false value may cause sessions to disappear
prematurely. The resource pool will not check that the session still exists
when issuing the callback so this may cause problems.

=head1 METHODS

=over 4

=item new %args

=item spawn %args

Construct a new resource pool.

See L</ATTRIBUTES> for parameters.

C<spawn> is provided as an alias due to L<POE::Component> convensions.

=item request %args

=item request $req

Queues a new request, optionally creating a request object based on the
C<request_class> attribute.

See L<POE::Component::ResourcePool::Request>.

=item create_request %args

Used by C<request> to create a request object with some default arguments in
addition to the supplied ones.

Delegates to C<construct_request>.

=item construct_request @args

Calls C<new> on the class returned by C<request_class> with the provided arguments.

=item queue $request

Inserts the request into the queue.

=item dismiss $request

Deallocates the request if it has been fulfilled, or cancels it otherwise.

=item shutdown

Remove the alias for the pool, causing its session to close.

=item resource_updated $resource, [ @requests ]

Called by resources to signal that a resource has been updated.

C<@requests> can be specified in order to only recheck certain requests
(instead of all the requests associated with the resource).

=item pending_requests

Returns a list of the currently pending requests.

If a resource is specified as the first argument then only returns the requests
for that resource.

=item allocated_requests

Returns a list of the currently allocated requests.

If a resource is specified as the first argument then only returns the requests
for that resource.

=item all_requests

Returns all the requests active in the pool (pending and allocated).

If a resource is specified as the first argument then only returns the requests
for that resource.

=back

=head1 ATTRIBUTES

=over 4

=item resources

The hash of resources to manage.

Resources may be shared by several pools.

Modifying this hash is not supported yet but might be in the future using a
method API.

=item alias

Comes from L<MooseX::POE::Aliased>.

Note that the alias is not currently useful for anything, since the only events
the resource pool currently responds to are internal.

=item request_class

The class to use when constructing new request objects.

=item weak_queue

Normally strong references are made to requests in the queue, to prevent their
destruction.

When requests leave the queue all references to them maintained by the pool are
weak, so that if the request gets garbage collected its allocations may be
returned to the resources.

If this parameter is set then unfulfilled requests will also be weak, so that
requests which are no longer referenced elsewhere are canceled.

=item refcount_pending

Whether or not to maintain POE reference counts for sessions that have pending
requests.

Defaults to true.

See L</REFERENCE MANAGEMENT>.

=item refcount_allocated

Whether or not to maintain POE reference counts for sessions that have
allocated requests.

Defaults to false.

See L</REFERENCE MANAGEMENT>.

=back

=head1 TODO

=head2 Prioritization

Resource contention is a problem, so a pluggable scheduler should be available,
with the default one being a FIFO (the current order is based on
L<Set::Object>'s internal hasing).

The module should ship with a priority based FIFO queue that supports priority
inheritence as well, in order to provide decent prioritization facilities out
of the box.

=head2 Nestability

Allow pools to also behave as resources in other pools.

This should be fairly easy.

=head2 Allow weak lifetime without an alias

Try to find a way for L<POE> to keep the pool alive as long as other sessions
may use it, just like when it's got an alias, but without needing to set one.

This is very annoying for resources that need their own sessions, as it rarely
akes sense for them to also have aliases.

=head1 VERSION CONTROL

This module is maintained using Darcs. You can get the latest version from
L<http://nothingmuch.woobling.org/code>, and use C<darcs send> to commit
changes.

=head1 AUTHOR

Yuval Kogman E<lt>nothingmuch@woobling.orgE<gt>

=head1 COPYRIGHT

	Copyright (c) 2008 Yuval Kogman. All rights reserved
	This program is free software; you can redistribute
	it and/or modify it under the same terms as Perl itself.

=cut
