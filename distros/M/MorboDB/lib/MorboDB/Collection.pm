package MorboDB::Collection;

# ABSTRACT: A MorboDB collection

use Moo;
use boolean;
use Carp;
use Clone qw/clone/;
use MorboDB::Cursor;
use MorboDB::OID;
use MQUL 0.003 qw/update_doc/;
use Scalar::Util qw/blessed/;

our $VERSION = "1.000000";
$VERSION = eval $VERSION;

=head1 NAME

MorboDB::Collection - A MorboDB collection

=head1 VERSION

version 1.000000

=head1 SYNOPSIS

	my $coll = $db->get_collection('users');
	
	my $id = $coll->insert({
		username => 'someguy98',
		password => 's3cr3t',
		email => 'email at address dot com',
	});

	my $cursor = $coll->find({ email => qr/\@address\.com$/ })->sort({ username => 1 });
	# use cursor according to MorboDB::Cursor

=head1 DESCRIPTION

This module provides the API for handling collections in a L<MorboDB::Database>.

=head1 ATTRIBUTES

=head2 name

The name of the collection. String, required.

=head2 full_name

The full name of the collection, including the name of the database, joined
by dots. String, created automatically.

=cut

has 'name' => (is => 'ro', required => 1);

has 'full_name' => (is => 'ro', lazy_build => 1);

has '_database' => (is => 'ro', required => 1, weak_ref => 1);

has '_data' => (is => 'ro', default => sub { {} }, clearer => '_clear_data');

=head1 STATIC FUNCTIONS

=head2 to_index_string( $keys )

Receives a hash-reference, array-reference or L<Tie::IxHash> object and
converts into a query string.

=cut

sub to_index_string {
	# this function is just stolen as-is from MongoDB::Collection
	my $keys = shift;

	my @name;
	if (ref $keys eq 'ARRAY' || ref $keys eq 'HASH') {
		while ((my $idx, my $d) = each(%$keys)) {
			push(@name, $idx);
			push(@name, $d);
		}
	} elsif (ref $keys eq 'Tie::IxHash') {
		my @ks = $keys->Keys;
		my @vs = $keys->Values;
		@vs = $keys->Values;

		for (my $i=0; $i<$keys->Length; $i++) {
			push(@name, $ks[$i]);
			push(@name, $vs[$i]);
		}
	} else {
		confess 'expected Tie::IxHash, hash, or array reference for keys';
	}

	return join('_', @name);
}

=head1 OBJECT METHODS

=head2 get_collection( $name )

Returns a MorboDB::Collection for the collection called C<$name> within this collection.

=cut

sub get_collection {
	my ($self, $name) = @_;

	return $self->_database->get_collection($self->name.'.'.$name);
}

=head2 find( [ $query ] )

Executes the given query and returns a L<MorboDB::Cursor> object with the
results (if query is not provided, all documents in the collection will
match). C<$query> can be a hash reference, a L<Tie::IxHash> object, or
array reference (with an even number of elements).

The set of fields returned can be limited through the use of the
C<< MorboDB::Cursor->fields() >> method on the resulting cursor object.
Other commonly used cursor methods are C<limit()>, C<skip()>, and C<sort()>.

As opposed to C<< MongoDB::Collection->find() >>, this method doesn't take a hash-ref
of options such as C<fields> and C<sort>, use the appropriate methods on
the cursor instead (this is also deprecated in MongoDB anyway).

Note that currently, providing a C<Tie::IxHash> object or array reference
will have no special effect, as the query will be converted into a hash
reference. This may or may not change in future version.

For a complete reference on querying in MorboDB, please look at L<MQUL::Reference/"QUERY STRUCTURES">.

=cut

sub find {
	my ($self, $query) = @_;

	confess "query must be a hash reference, even-numbered array reference or Tie::IxHash object."
		if $query &&	ref $query ne 'HASH' &&
				ref $query ne 'Tie::IxHash' &&
				(ref $query ne 'ARRAY' ||
					(ref $query eq 'ARRAY' && scalar @$query % 2 != 0)
				);

	# turn array queries into Tie::IxHash objects
	if ($query && ref $query eq 'ARRAY') {
		$query = Tie::IxHash->new(@$query);
	}

	# turn Tie::IxHash objects into hash-refs
	if ($query && ref $query eq 'Tie::IxHash') {
		my %new_query = map { $_ => $query->FETCH($_) } $query->Keys;
		$query = \%new_query;
	}

	$query ||= {};

	return MorboDB::Cursor->new(_coll => $self, _query => $query);
}

=head2 query( [ $query ] )

Alias for C<find()>.

=cut

sub query { shift->find(@_) }

=head2 find_one( [ $query ] )

Executes the provided query and returns the first result found (if any,
otherwise C<undef> is returned).

Internally, this is really a shortcut for running C<< $coll->find($query)->limit(1)->next() >>.

=cut

sub find_one { shift->find(@_)->limit(1)->next }

=head2 insert( $doc )

Inserts the given document into the database and returns it's ID.
The document can be a hash reference, an even-numbered array reference
or a Tie::IxHash object. The ID is the _id value specified in the data
or a L<MorboDB::OID> object created automatically.

Note that providing a Tie::IxHash object or array reference will not make
your document ordered, as documents are always saved as hash references,
so this has no benefit except compatibility with MongoDB.

=cut

sub insert { ($_[0]->batch_insert([$_[1]]))[0] }

=head2 batch_insert( \@docs )

Inserts each of the documents in the array into the database and returns
an array of their _id attributes.

=cut

sub batch_insert {
	my ($self, $docs) = @_;

	confess "batch_insert() expects an array reference of documents."
		unless $docs && ref $docs eq 'ARRAY';

	foreach my $doc (@$docs) {
		confess "data to insert must be a hash reference, even-numbered array reference or Tie::IxHash object."
			unless $doc && (ref $doc eq 'HASH' || ref $doc eq 'Tie::IxHash' || (ref $doc eq 'ARRAY' && scalar @$doc % 2 == 0));

		# turn array documents into Tie::IxHash objects
		if ($doc && ref $doc eq 'ARRAY') {
			$doc = Tie::IxHash->new(@$doc);
		}

		# turn Tie::IxHash objects into hash-refs
		if ($doc && ref $doc eq 'Tie::IxHash') {
			my %new_doc = map { $_ => $doc->FETCH($_) } $doc->Keys;
			$doc = \%new_doc;
		}

		$doc->{_id} ||= MorboDB::OID->new;

		my $oid = blessed $doc->{_id} && blessed $doc->{_id} eq 'MorboDB::OID' ?
			$doc->{_id}->value : $doc->{_id};
		confess "duplicate key error, ID $oid already exists in the collection."
			if exists $self->_data->{$oid};
	}

	return map { $self->save($_) } @$docs;
}

=head2 update( $query, \%update, [ \%opts ] )

Updates document(s) that match the provided query (which is the same as
what C<find()> accepts) according to the update (C<\%update>) hash-ref.

Return a hash-ref of information about the update, including number of documents
updated (n).

C<update()> can take a hash reference of options. The options currently supported are:

=over

=item * C<upsert> - If no object matches the query, C<\%update> will be inserted
as a new document (possibly taking values from C<$query> too).

=item * C<multiple> - All of the documents that match the query will be updated,
not just the first document found.

=back

For a complete reference on update syntax and behavior, please look at
L<MQUL::Reference/"UPDATE STRUCTURES">.

=cut

sub update {
	my ($self, $query, $update, $opts) = @_;

	confess "query must be a hash reference, even-numbered array reference or Tie::IxHash object."
		if $query &&	ref $query ne 'HASH' &&
				ref $query ne 'Tie::IxHash' &&
				(ref $query ne 'ARRAY' ||
					(ref $query eq 'ARRAY' && scalar @$query % 2 != 0)
				);

	$query ||= {};

	confess "the update structure must be a hash reference."
		unless $update && ref $update eq 'HASH';

	confess "the options structure must be a hash reference."
		if $opts && ref $opts ne 'HASH';

	$opts ||= {};

	my @docs;
	if ($opts->{multiple}) {
		@docs = $self->find($query)->all;
	} else {
		my $doc = $self->find_one($query);
		push(@docs, $doc) if $doc;
	}

	if (scalar @docs == 0 && $opts->{upsert}) {
		# take attributes from the query where appropriate
		my $doc = {};
		foreach (keys %$query) {
			next if $_ eq '_id';
			$doc->{$_} = $query->{$_}
				if !ref $query->{$_};
		}
		$doc->{_id} ||= MorboDB::OID->new;
		my $id = $self->save(update_doc($doc, $update));
		return {
			ok => 1,
			n => 1,
			upserted => $id,
			updatedExisting => false,
			wtime => 0,
		};
	} else {
		foreach (@docs) {
			$self->save(update_doc($_, $update));
		}
		return {
			ok => 1,
			n => scalar @docs,
			updatedExisting => true,
			wtime => 0,
		};
	}
}

=head2 remove( [ $query, \%opts ] )

Removes all objects matching the given query from the database. If a query
is not given, removes all objects from the collection.

Returns a hash-ref of information about the remove, including how many
documents were removed (n).

C<remove()> can take a hash reference of options. The options currently supported are:

=over

=item * C<just_one> - Only one matching document to be removed instead of all.

=back

=cut

sub remove {
	my ($self, $query, $opts) = @_;

	confess "query must be a hash reference, even-numbered array reference or Tie::IxHash object."
		if $query &&	ref $query ne 'HASH' &&
				ref $query ne 'Tie::IxHash' &&
				(ref $query ne 'ARRAY' ||
					(ref $query eq 'ARRAY' && scalar @$query % 2 != 0)
				);

	confess "the options structure must be a hash reference."
		if $opts && ref $opts ne 'HASH';

	$query ||= {};
	$opts ||= {};

	my @docs = $opts->{just_one} ? ($self->find_one($query)) : $self->find($query)->all;
	foreach (@docs) {
		my $oid = blessed $_->{_id} && blessed $_->{_id} eq 'MorboDB::OID' ?
			$_->{_id}->value : $_->{_id};
		delete $self->_data->{$oid};
	}

	return {
		ok => 1,
		n => scalar @docs,
		wtime => 0,
	};
}

=head2 ensure_index()

Not implemented. Simply returns true here.

=cut

sub ensure_index { 1 } # not implemented

=head2 save( \%doc )

Inserts a document into the database if it does not have an C<_id> field,
upserts it if it does have an C<_id> field. Mostly used internally. Document
must be a hash-reference.

=cut

sub save {
	my ($self, $doc) = @_;

	confess "document to save must be a hash reference."
		unless $doc && ref $doc eq 'HASH';

	$doc->{_id} ||= MorboDB::OID->new;

	my $oid = blessed $doc->{_id} && blessed $doc->{_id} eq 'MorboDB::OID' ?
		$doc->{_id}->value : $doc->{_id};

	$self->_data->{$oid} = clone($doc);

	return $doc->{_id};
}

=head2 count( [ $query ] )

Shortcut for running C<< $coll->find($query)->count() >>.

=cut

sub count {
	my ($self, $query) = @_;

	$self->find($query)->count;
}

=head2 validate()

Not implemented. Returns an empty hash-ref here.

=cut

sub validate { {} } # not implemented

=head2 drop_indexes()

Not implemented. Returns true here.

=cut

sub drop_indexes { 1 } # not implemented

=head2 drop_index()

Not implemented. Returns true here.

=cut

sub drop_index { 1 } # not implemented

=head2 get_indexes()

Not implemented. Returns false here.

=cut

sub get_indexes { return } # not implemented

=head2 drop()

Deletes the collection and all documents in it.

=cut

sub drop {
	my $self = shift;

	$self->_clear_data;
	delete $self->_database->_colls->{$self->name};
	return;
}

sub _build_full_name { $_[0]->_database->name.'.'.$_[0]->name }

=head1 DIAGNOSTICS

This module throws the following exceptions:

=over

=item C<< expected Tie::IxHash, hash, or array reference for keys >>

This error is returned by the static C<to_index_string()> function if you're
not providing it with a hash reference, array reference (even-numbered)
or Tie::IxHash object.

=item C<< query must be a hash reference, even-numbered array reference or Tie::IxHash object. >>

This error is returned by the C<find()>, C<query()>, C<update()>, C<remove()>
and C<count()> methods, that expect a query that is either a hash reference, even-numbered
array reference or Tie::IxHash object. Just make sure you're providing
a valid query variable.

=item C<< batch_insert() expects an array reference of documents. >>

This error is thrown by C<batch_insert()> if you're not giving it an
array reference of documents to insert into the database.

=item C<< data to insert must be a hash reference, even-numbered array reference or Tie::IxHash object. >>

This error is thrown by C<insert()> and C<batch_insert()> when you're providing
them with a document which is not a hash reference, even-numbered array
reference or Tie::IxHash object. Just make sure your document(s) is/are
valid.

=item C<< duplicate key error, ID %s already exists in the collection. >>

This error is thrown by C<insert()> and C<batch_insert()>, when you're trying
to insert a document with an C<_id> attribute that already exists in the
collection. If you're trying to update a document you know already exists,
use the C<update()> method instead. Otherwise you're just doing it wrong.

=item C<< the update structure must be a hash reference. >>

This error is thrown by the C<update()> method when you're not giving it
a proper update hash-ref, as described by L<MQUL::Reference/"UPDATE STRUCTURES">.

=item C<< the options structure must be a hash reference. >>

This error is thrown by C<update()> when you're providing it with a third
argument that should be an options hash-ref, or by the C<remove()> method
when you're providing it with a second argument that should be an options
hash-ref. Just make sure you're not sending non hash-refs to these methods.

=item C<< document to save must be a hash reference. >>

This error is thrown by the C<save()> method when it receives a document
which is not a hash reference. If this happens when invoking C<insert()>
or C<batch_insert()>, and non of the specific errors of these methods were
thrown, please submit a bug report. Otherwise (if you've called C<save()>
directly, please make sure you're providing a hash reference. As opposed
to C<insert()> and C<batch_insert()>, C<save()> does not take a Tie::IxHash
objects or even-numbered array references.

=back

=head1 BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests to
C<bug-MorboDB@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=MorboDB>.

=head1 SEE ALSO

L<MongoDB::Collection>.

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
