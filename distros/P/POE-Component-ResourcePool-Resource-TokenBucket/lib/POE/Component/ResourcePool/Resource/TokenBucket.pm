#!/usr/bin/perl

package POE::Component::ResourcePool::Resource::TokenBucket;
use MooseX::POE;

with qw(POE::Component::ResourcePool::Resource);

use Tie::RefHash::Weak;
use POE;
use Algorithm::TokenBucket;

our $VERSION = "0.01";

with qw(MooseX::POE::Aliased);

sub shutdown { shift->clear_alias }

has token_bucket => (
	isa => "Algorithm::TokenBucket",
	is  => "ro",
	init_arg => undef,
	lazy_build => 1,
);

sub _build_token_bucket {
	my $self = shift;
	
	Algorithm::TokenBucket->new( $self->rate, $self->burst );
}

has rate => (
	isa => "Num",
	is  => "ro",
	required => 1,
);

has burst => (
	isa => "Num",
	is  => "ro",
	required => 1,
);

has _requests => (
	isa => "HashRef",
	is  => "ro",
	init_arg => undef,
	default => sub { Tie::RefHash::Weak::fieldhash my %h },
);

sub could_allocate {
	my ( $self, $pool, $request, $value ) = @_;

	return $value <= $self->burst;
}

sub try_allocating {
	my ( $self, $pool, $request, $value ) = @_;

	if ( my $until = $self->token_bucket->until($value) ) {
		$self->yield( delay_notification => $until, $pool, $request, $value );
		return;
	} else {
		return $value;
	}
}

sub finalize_allocation {
	my ( $self, $pool, $request, $value ) = @_;

	$self->token_bucket->count($value);

	return $value;
}

sub free_allocation {
	return;
}

sub forget_request {
	my ( $self, $pool, $request ) = @_;

	if ( my $alarm = $self->_requests->{$request} ) {
		$poe_kernel->alarm_remove($alarm);
	}
}

event delay_notification => sub {
	my ( $kernel, $self, $until, $pool, $request, $value ) = @_[KERNEL, OBJECT, ARG0 .. $#_];

	$self->_requests->{$request} = $kernel->delay_set( request_may_be_free => $until, $pool, $request, $value );
};

event request_may_be_free => sub {
	my ( $kernel, $self, $pool, $request, $value ) = @_[KERNEL, OBJECT, ARG0 .. $#_];

	if ( my $until = $self->token_bucket->until($value) ) {
		$self->_requests->{$request} = $kernel->delay_set( request_may_be_free => $until, $pool, $request, $value );
	} else {
		delete $self->_requests->{$request};
		$request->pool->resource_updated( $self, $request );
	}
};

__PACKAGE__

__END__

=pod

=head1 NAME

POE::Component::ResourcePool::Resource::TokenBucket - Token bucket based
resource (for throttling).

=head1 SYNOPSIS

	use POE::Component::ResourcePool::Resource::TokenBucket;

	my $tb = POE::Component::ResourcePool::Resource::TokenBucket->new(
		# see Algorithm::TokenBucket
		rate => $per_second,
		burst => $max_item_size,
	);

	my $pool = POE::Component::ResourcePool->new(
		resources => {
			rate_limit => $tb,
		},
	);

	# requests can ask the rate_limit resource to throttle them now

=head1 DESCRIPTIONS

This class implements an L<Algorithm::TokenBucket> based resource for
L<POE::Component::ResourcePool>.

Requests are numeric value based, and will be served as the token bucket fills.

This is useful for rate limiting of jobs in a time based way.

=head1 ATTRIBUTES

=over 4

=item alias

The POE alias for the internal session.

Comes from L<MooseX::POE::Aliased>.

The alias can be set explicitly but is not yet useful for anything (there is no
POE side API for this object, all session states are internal).

=item token_bucket

The L<Algorithm::TokenBucket> object used to calculate the rate limiting.

This is readonly.

=item rate

=item burst

The numerical parameters for L<Algorithm::TokenBucket> used to generate
C<token_bucket>.

These are also used for C<could_allocate>, etc.

=back

=head1 METHODS

See L<POE::Component::ResourcePool::Resource> for the resource API.

=head1 SEE ALSO

L<POE>, L<MooseX::POE>, L<Algorithm::TokenBucket>,
L<POE::Component::ResourcePool>.

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
