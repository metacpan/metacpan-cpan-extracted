package MorboDB::Cursor;

# ABSTRACT: A cursor/iterator for MorboDB query results

use Moo;
use Carp;
use Clone qw/clone/;
use MQUL 0.003 qw/doc_matches/;
use Tie::IxHash;

our $VERSION = "1.000000";
$VERSION = eval $VERSION;

=head1 NAME

MorboDB::Cursor - A cursor/iterator for MorboDB query results

=head1 VERSION

version 1.000000

=head1 SYNOPSIS

	my $cursor = $coll->find({ year => { '$gte' => 2000 } })->sort({ year => -1 });
	while (my $object = $cursor->next) {
		...
	}

	my @objects = $cursor->all;

=head1 DESCRIPTION

This module provides an iterator/cursor for query operations performed
on a L<MorboDB::Collection> using the C<find()>/C<query()> methods.

=head1 ATTRIBUTES

=head2 started_iterating

A boolean value indicating whether the cursor has started looking for
documents in the database. Initially false. When true, setting modifiers
such as C<sort>, C<fields>, C<skip> and C<limit> is not possible without
first calling C<reset()>.

=head2 immortal

Boolean value, means nothing in MorboDB.

=head2 tailable

Boolean value, not implemented in MorboDB.

=head2 partial

Boolean value, not implemented in MorboDB.

=head2 slave_okay

Boolean value, not implemented in MorboDB.

=cut

has 'started_iterating' => (is => 'ro', default => 0, writer => '_set_started_iterating');

has 'immortal' => (is => 'rw', default => 0); # unimplemented

has 'tailable' => (is => 'rw', default => 0); # unimplemented

has 'partial' => (is => 'rw', default => 0); # unimplemented

has 'slave_okay' => (is => 'rw', default => 0); # unimplemented

has '_coll' => (is => 'ro', required => 1);

has '_query' => (is => 'ro', required => 1);

has '_fields' => (is => 'ro', writer => '_set_fields', clearer => '_clear_fields');

has '_limit' => (is => 'ro', default => 0, writer => '_set_limit', clearer => '_clear_limit');

has '_skip' => (is => 'ro', default => 0, writer => '_set_skip', clearer => '_clear_skip');

has '_sort' => (is => 'ro', predicate => '_has_sort', writer => '_set_sort', clearer => '_clear_sort');

has '_docs' => (is => 'ro', writer => '_set_docs', clearer => '_clear_docs');

has '_index' => (is => 'ro', default => 0, writer => '_set_index');

=head1 OBJECT METHODS

=head2 fields( \%fields )

Selects which fields are returned. The default is all fields. C<_id> is always returned.
Returns this cursor for chaining operations.

=cut

sub fields {
	my ($self, $f) = @_;

	confess 'cannot set fields after querying'
		if $self->started_iterating;

	confess 'not a hash reference'
		unless ref $f && ref $f eq 'HASH';

	$self->_set_fields($f);

	return $self;
}

=head2 limit( $num )

Returns a maximum of C<$num> results. Returns this cursor for chaining operations.

=cut

sub limit {
	my ($self, $num) = @_;

	confess 'cannot set limit after querying'
		if $self->started_iterating;

	$self->_set_limit($num);

	return $self;
}

=head2 skip( $num )

Skips the first C<$num> results. Returns this cursor for chaining operations.

=cut

sub skip {
	my ($self, $num) = @_;

	confess 'cannot set skip after querying'
		if $self->started_iterating;

	$self->_set_skip($num);

	return $self;
}

=head2 sort( $order )

Adds a sort to the cursor. Argument is either a hash reference or a
L<Tie::IxHash> object. Returns this cursor for chaining operations.

=cut

sub sort {
	my ($self, $order) = @_;

	confess 'cannot set sort after querying'
		if $self->started_iterating;

	if ($order && ref $order eq 'Tie::IxHash') {
		$self->_set_sort($order);
	} elsif ($order && ref $order eq 'HASH') {
		my $obj = Tie::IxHash->new;
		foreach (keys %$order) {
			$obj->Push($_ => $order->{$_});
		}
		$self->_set_sort($obj);
	} else {
		confess 'sort() needs a Tie::IxHash object or a hash reference.';
	}

	return $self;
}

=head2 snapshot()

Not implemented. Simply returns true here.

=cut

sub snapshot {
	# NOT IMPLEMENTED YET (IF EVEN SHOULD BE)
	1;
}

=head2 explain()

Not implemented. Simply returns true here.

=cut

sub explain {
	# NOT IMPLEMENTED YET
	1;
}

=head2 reset()

Resets the cursor. After being reset, pre-query methods can be called
on the cursor (C<sort>, C<limit>, etc.) and subsequent calls to C<next()>,
C<has_next()>, or C<all()> will re-query the database.

=cut

sub reset {
	my $self = shift;

	$self->_set_started_iterating(0);
	$self->_clear_fields;
	$self->_clear_limit;
	$self->_clear_skip;
	$self->_clear_sort;
	$self->_clear_docs;
	$self->_set_index(0);

	return 1;
}

=head2 info()

Not implemented. Returns an empty hash-ref here.

=cut

sub info {
	# NOT IMPLEMENTED YET
	{};
}

=head2 count()

Returns the number of documents the query matched.

=cut

sub count {
	my $self = shift;

	unless ($self->started_iterating) {
		# haven't started iterating yet, let's query the database
		$self->_query_db;
	}

	return scalar @{$self->_docs};
}

=head2 has_next()

Checks if there is another result to fetch.

=cut

sub has_next {
	my $self = shift;

	unless ($self->started_iterating) {
		# haven't started iterating yet, let's query the database
		$self->_query_db;
	}

	return $self->_index < $self->count;
}

=head2 next()

Returns the next object in the cursor. Returns C<undef> if no more data is available.

=cut

sub next {
	my $self = shift;

	# return nothing if we've started iterating but have no more results
	return if $self->started_iterating && !$self->has_next;

	unless ($self->started_iterating) {
		# haven't started iterating yet, let's query the database
		$self->_query_db;
		return unless $self->count;
	}

	my $doc = clone($self->_coll->_data->{$self->_docs->[$self->_index]});
	$self->_inc_index;

	if ($self->_fields) {
		my $ret = {};
		foreach (keys %{$self->_fields}) {
			$ret->{$_} = $doc->{$_}
				if exists $self->_fields->{$_} || $_ eq '_id';
		}
		return $ret;
	} else {
		return $doc;
	}
}

=head2 all()

Returns an array of all objects in the result.

=cut

sub all {
	my $self = shift;

	my @docs;
	while ($self->has_next) {
		push(@docs, $self->next);
	}

	return @docs;
}

sub _query_db {
	my $self = shift;

	my @docs;
	my $skipped = 0;
	foreach (keys %{$self->_coll->_data || {}}) {
		if (doc_matches($self->_coll->_data->{$_}, $self->_query)) {
			# are we skipping this? we should only skip
			# here if we're not sorting, otherwise we
			# need to do that later, after we've sorted
			if (!$self->_has_sort && $self->_skip && $skipped < $self->_skip) {
				$skipped++;
				next;
			} else {
				push(@docs, $_);
			}
		}

		# have we reached our limit yet? if so, bail, but
		# only if we're not sorting, otherwise we need to
		# sort _all_ results first
		last if $self->_limit && scalar @docs == $self->_limit;
	}

	# okay, are we sorting?
	if ($self->_has_sort) {
		@docs = sort {
			# load the documents
			my $doc_a = $self->_coll->_data->{$a};
			my $doc_b = $self->_coll->_data->{$b};
			
			# start comparing according to $order
			# this is stolen from my own Giddy::Collection::sort() code
			foreach my $attr ($self->_sort->Keys) {
				my $dir = $self->_sort->FETCH($attr);
				if (defined $doc_a->{$attr} && !ref $doc_a->{$attr} && defined $doc_b->{$attr} && !ref $doc_b->{$attr}) {
					# are we comparing numerically or alphabetically?
					if ($doc_a->{$attr} =~ m/^\d+(\.\d+)?$/ && $doc_b->{$attr} =~ m/^\d+(\.\d+)?$/) {
						# numerically
						if ($dir > 0) {
							# when $dir is positive, we want $a to be larger than $b
							return 1 if $doc_a->{$attr} > $doc_b->{$attr};
							return -1 if $doc_a->{$attr} < $doc_b->{$attr};
						} elsif ($dir < 0) {
							# when $dir is negative, we want $a to be smaller than $b
							return -1 if $doc_a->{$attr} > $doc_b->{$attr};
							return 1 if $doc_a->{$attr} < $doc_b->{$attr};
						}
					} else {
						# alphabetically
						if ($dir > 0) {
							# when $dir is positive, we want $a to be larger than $b
							return 1 if $doc_a->{$attr} gt $doc_b->{$attr};
							return -1 if $doc_a->{$attr} lt $doc_b->{$attr};
						} elsif ($dir < 0) {
							# when $dir is negative, we want $a to be smaller than $b
							return -1 if $doc_a->{$attr} gt $doc_b->{$attr};
							return 1 if $doc_a->{$attr} lt $doc_b->{$attr};
						}
					}
				} else {
					# documents cannot be compared for this attribute
					# we want documents that have the attribute to appear
					# earlier in the results, so let's find out if
					# one of the documents has the attribute
					return -1 if defined $doc_a->{$attr} && !defined $doc_b->{$attr};
					return 1 if defined $doc_b->{$attr} && !defined $doc_a->{$attr};
					
					# if we're here, either both documents have the
					# attribute but it's non comparable (since it's a
					# reference) or both documents don't have that
					# attribute at all. in both cases, we consider them
					# to be equal when comparing these attributes,
					# so we don't return anything and just continue to
					# the next attribute to sort according to (if any)
				}
			}

			# if we've reached this point, the documents compare entirely
			# so we need to return zero
			return 0;
		} @docs;

		# let's limit (and possibly skip) the results if we need to
		splice(@docs, 0, $self->_skip)
			if $self->_skip;
		splice(@docs, $self->_limit, scalar(@docs) - $self->_limit)
			if $self->_limit && scalar @docs > $self->_limit;
	}

	$self->_set_started_iterating(1);
	$self->_set_docs(\@docs);
}

sub _inc_index {
	my $self = shift;

	$self->_set_index($self->_index + 1);
}

=head1 DIAGNOSTICS

This module throws the following exceptions:

=over

=item C<< cannot set fields/skip/limit/sort after querying >>

This error will be thrown when you're trying to modify the cursor after
it has already started querying the database. You can tell if the cursor
already started querying the database by taking a look at the C<started_iterating>
attribute. If you want to modify the cursor after iteration has started,
you can used the C<reset()> method, but the query will have to run again.

=item C<< not a hash reference >>

This error is thrown by the C<fields()> method when you're not providing it
with a hash-reference of fields like so:

	$cursor->fields({ name => 1, datetime => 1 });

=item C<< sort() needs a Tie::IxHash object or a hash reference. >>

This error is thrown by the C<sort()> method when you're not giving it
a hash reference or L<Tie::IxHash> object to sort according to, like so:

	$cursor->sort(Tie::IxHash->new(name => 1, datetime => -1));

=back

=head1 BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests to
C<bug-MorboDB@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=MorboDB>.

=head1 SEE ALSO

L<MongoDB::Cursor>.

=head1 AUTHOR

Ido Perlmuter <ido@ido50.net>

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2011-2013, Ido Perlmuter C<< ido@ido50.net >>.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself, either version
5.8.1 or any later version. See L<perlartistic|perlartistic> 
and L<perlgpl|perlgpl>.

The full text of the license can be found in the
LICENSE file included with this module.

=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.

=cut

__PACKAGE__->meta->make_immutable;
__END__
