#!/usr/bin/perl

package POE::Component::ResourcePool::Request;
use Moose;

use Carp::Clan qr/^(?:POE::Component::ResourcePool|Moose|Class::MOP)/;

use POE;

has session_id => (
	is  => "ro",
	default => sub { $poe_kernel->get_active_session->ID },
);

has event => (
	isa => "Str",
	is  => "ro",
);

has callback => (
	isa => "CodeRef|Str",
	is  => "rw",
	lazy_build => 1,
);

sub BUILD {
	my $self = shift;
	$self->callback; # force builder
}

sub _build_callback {
	my $self = shift;

	my $event = $self->event;

	unless ( defined $event ) {
		croak "Either 'event' or 'callback' is a required parameter";
	}

	my $session_id = $self->session_id;

	return sub {
		my ( $self, @args ) = @_;
		$poe_kernel->post( $session_id, $event, request => $self, @args );
	};
}

has params => (
	isa => "HashRef",
	is  => "rw",
	required => 1,
);

has pool => (
	isa => "POE::Component::ResourcePool",
	is  => "ro",
	required => 1,
);

has dismissed => (
	isa => "Bool",
	is  => "rw",
	default  => 0,
	init_arg => undef,
	writer   => "_dismissed",
);

has fulfilled => (
	isa => "Bool",
	is  => "rw",
	default  => 0,
	init_arg => undef,
	writer   => "_fulfilled",
);

sub canceled {
	my $self = shift;
	$self->dismissed && !$self->fulfilled;
}

has results => (
	isa => "HashRef",
	is  => "rw",
	init_arg => undef,
	writer => "_results",
);

sub dismiss {
	my $self = shift;

	if ( my $pool = $self->pool ) { # might be false in global destruction
		$pool->dismiss($self);
	}
}

sub invoke_callback {
	my ( $self, @args ) = @_;

	my $cb = $self->callback;

	$self->$cb( @args );
}

sub DEMOLISH {
	my $self = shift;
	$self->dismiss;
}

__PACKAGE__

__END__

=pod

=head1 NAME

POE::Component::ResourcePool::Request - A bundle of resource request
parameters.

=head1 SYNOPSIS

	$pool->request(
		# specify what you want
		params => {
			resource_name  => ...,
			other_resource => ...,
		},

		# specify what to do when you've got what you want
		event => "moose",

	);

=head1 DESCRIPTION

The request object represents a bundle of required resources in the queue.

A request will wait in a pool's queue until sufficient resources are available
to dispatch them, at which point its callback will be triggerred.

=head1 RESOURCE MANAGEMENT

A request can be deallocated by calling C<dismiss>, returning the allocated
value to the resource.

When a resource is garbage collected it will call C<dismiss> automatically.

C<dismiss> can also be called before the request is fulfilled in order to
cancel it.

=head1 METHODS

=over 4

=item new

Create a new request

=item dismiss

If the request has already been fulfilled then deallocate it, otherwise cancel
it.

=item dismissed

Returns a boolean value denoting whether or not the request has been dismissed.

=item fulfilled

Returns a boolean value denoting whether or not the request has been fulfilled.

=item canceled

Returns a boolean value denoting whether or not the request has been canceled
(dismissed but not fulfilled).

=back

=head1 ATTRIBUTES

=over 4

=item callback

The callback to call when the request is fulfilled.

See also the C<event> attribute.

=item event

An event name to C<post> to on the currently active session at the time of the
resource's creation. Used to generate a default C<callback>.

=item session_id

THe ID of the currently active session at the time of the resource's creation.
Used to generate a default C<callback> and to increment the reference count of
sessions waiting on resources.

If the current session is not the session that the request should be associated
with then this parameter may be specified, but in general that is discouraged.

=back

=cut
