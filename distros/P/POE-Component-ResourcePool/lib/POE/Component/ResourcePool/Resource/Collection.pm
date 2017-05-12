#!/usr/bin/perl

package POE::Component::ResourcePool::Resource::Collection;
use Moose;

with qw(POE::Component::ResourcePool::Resource);

has values => (
	isa => "ArrayRef",
	is  => "rw",
	required => 1,
);

sub try_allocating {
	my ( $self, $pool, $request, $count ) = @_;

	$count ||= 1;

	my $values = $self->values;
	if ( @$values >= $count ) {
		return @{ $values }[ 0 .. $count-1 ];
	} else {
		return;
	}
}

sub finalize_allocation {
	my ( $self, $pool, $request, @values ) = @_;

	splice @{ $self->values }, 0, scalar @values;

	return @values == 1 ? $values[1] : \@values;
}

sub free_allocation {
	my ( $self, $pool, $request, @values ) = @_;

	push @{ $self->values }, @values;

	$self->notify_all_pools;
}


__PACKAGE__

__END__

=pod

=head1 NAME

POE::Component::ResourcePool::Resource::Collection - A collection of valeus to
be shared (e.g. handles).

=head1 SYNOPSIS

	use POE::Component::ResourcePool::Resource::Collection;

	my $collection = POE::Component::ResourcePool::Resource::Collection->new(
		values => [ $handle1, $handle2, $handle3 ],
	);

	# ...

	my $pool = POE::Component::ResourcePool->new(
		resources => {
			handles => $collection,
		},
	);

	$pool->request(
		params => {
			handles => $how_many,
		},
		...
	);

=head1 DESCRIPTION

This resource allows the sharing of values from a collection in a round the
robin fashion.

It is useful for e.g. limiting the number of database handles to a certain
bound, but unlike the semaphore will pool the actual values instead of just
counting.

The parameter to the request can be a number denoting how many values are
required, with 1 being the default.

Unlike the semaphore resource C<could_allocate> is not strict, and will always
return true even if the count is bigger than the initial value list's size.
This is to facilitate editing of the value collection array yourself.

If you modify the C<values> attribute be sure to call C<notify_all_pools> in
order to check for potentially affected requests.

Note that you cannot reliably remove values from the C<values> array because
currently allocated values are not found in the list, but will be added later.

Subclassing this class with additional value tracking semantics should help
alleviate any issues due to this.

=head1 METHODS

=over 4

=item try_allocating

If there are enough values in C<values> to satisfy the count (defaults to 1)
then these items are return.

Otherwise allocation will fail.

=item finalize_allocation

Splices the allocated values out of the C<values> array.

=item free_allocation

Pushes the allocated values to the end of the C<values> array.

=back

=head1 ATTRIBUTES

=over 4

=item values

An array reference of values to be allocated.

Duplicate values are treated as separate values, and will not be checked for
(this is a feature).

=back

=cut


