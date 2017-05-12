#!/usr/bin/perl

package POE::Component::ResourcePool::Resource::TryList;
use Moose;

with 'POE::Component::ResourcePool::Resource';

has resources => (
	isa => "ArrayRef[POE::Component::ResourcePool::Resource]",
	is  => "rw",
	required => 1,
	auto_deref => 1,
);

sub _for_each_resource {
	my ( $self, $method, @args ) = @_;

	foreach my $resource ( $self->resources ) {
		$resource->$method(@args);
	}
}

sub forget_request {
	my ( $self, @args ) = @_;
	$self->_for_each_resource( forget_request => @args );
}

sub register_request {
	my ( $self, @args ) = @_;
	$self->_for_each_resource( register_request => @args );
}

before register_pool => sub {
	my ( $self, @args ) = @_;
	$self->_for_each_resource( register_pool => @args );
};

before unregister_pool => sub {
	my ( $self, @args ) = @_;
	$self->_for_each_resource( unregister_pool => @args );
};

sub try_allocating {
	my ( $self, @args ) = @_;

	foreach my $resource ( $self->resources ) {
		if ( my @allocation = $resource->try_allocating( @args ) ) {
			return ( $resource, @allocation );
		}
	}

	return;
}

sub could_allocate {
	my ( $self, @args ) = @_;

	foreach my $resource ( $self->resources ) {
		if ( $resource->could_allocate( @args ) ) {
			return 1;
		}
	}

	return;
}

sub finalize_allocation {
	my ( $self, $pool, $request, $resource, @allocation ) = @_;

	$resource->finalize_allocation( $pool, $request, @allocation );
}

sub free_allocation {
	my ( $self, $pool, $request, $resource, @allocation ) = @_;

	$resource->free_allocation( $pool, $request, @allocation );
}

__PACKAGE__

__END__

=pod

=head1 NAME

POE::Component::ResourcePool::Resource::TryList - Delegate to a number of
resources.

=head1 SYNOPSIS

	use POE::Component::ResourcePool::Resource::TryList;

	my $good = POE::Component::ResourcePool::Resource::Good->new( ... );

	my $better = POE::Component::ResourcePool::Resource::Better->new( ... );

	my $best = POE::Component::ResourcePool::Resource::TryList->new(
		resources => [ $better, $good ],
	);

=head1 DESCRIPTION

This class allows you to specify fallback lists for resources easily.

The resources will be delegated to appropriately.

The only difference is that sometimes resources that return false from
C<could_allocate> will still have C<try_allocating> called on them, because the
try list only requires that one of the sub resources return true from
C<could_allocate>.

It is trivial to subclass and override it such that C<could_allocate> only
returns true if all the sub resources do, thus resolving this issue. However,
this seems to have a diminished practical value to me.

=head1 ATTRIBUTES

=over 4

=item resources

The array of resources to deleate to.

=back

=cut


