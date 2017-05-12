package MongoDBx::Class::Collection;

# ABSTRACT: A MongoDBx::Class collection object

our $VERSION = "1.030002";
$VERSION = eval $VERSION;

use Moose;
use namespace::autoclean;
use Carp;
use version;

extends 'MongoDB::Collection';

=head1 NAME

MongoDBx::Class::Collection - A MongoDBx::Class collection object

=head1 VERSION

version 1.030002

=head1 EXTENDS

L<MongoDB::Collection>

=head1 SYNOPSIS

	# get a collection from a L<MongoDBx::Class::Database> object
	my $coll = $db->get_collection($coll_name); # or $db->$coll_name

	# insert a document
	my $doc = $coll->insert({ title => 'The Valley of Fear', year => 1914, author => 'Conan Doyle', _class => 'Novel' }, { safe => 1 });

	# find some documents
	my @docs = $coll->find({ author => 'Conan Doyle' })->sort({ year => 1 })->all;

=head1 DESCRIPTION

MongoDBx::Class::Collection extends L<MongoDB::Collection>. It adds some
convenient options to the syntax and a few method modifications to allow
automatic document expansion (when finding) and collapsing (when inserting).

If you're not familiar with L<MongoDB::Collection>, please read it first.

=head1 ATTRIBUTES

No special attributes are added.

=head1 OBJECT METHODS

The following methods are available along with all methods defined in
L<MongoDB::Collection>. However, most (or all) of those are modifications
of MongoDB::Collection methods.

=head2 find( \%query, [ \%attrs ] )

=head2 query( \%query, [ \%attrs ] )

=head2 search( \%query, [ \%attrs ] )

All three methods are equivalent (the last two aliases of the first).
These methods perform a search for documents in the collection for documents matching
a certain query and return a L<MongoDBx::Class::Cursor> object. Refer to
L<MongoDB::Collection/"find($query)"> for more information about queries.

These methods are modified in the following way:

1. They return a L<MongoDBx::Class::Cursor> object instead of a plain
L<MongoDB::Cursor> object.

2. The C<sort_by> attribute in the C<$attr> hash-ref can contain an
array-ref instead of a L<Tie::IxHash> object, such as:

	$coll->find({ some => 'thing' }, { sort_by => [ title => 1, some => -1 ] })

This array-ref will be converted into a Tie::IxHash object automatically.

=cut

override 'find' => sub {
	my ($self, $query, $attrs) = @_;

	# old school options - these should be set with MongoDB::Cursor methods
	my ($limit, $skip, $sort_by) = @{ $attrs || {} }{qw/limit skip sort_by/};

	$limit ||= 0;
	$skip ||= 0;

	my $q = {};
	if ($sort_by) {
		$sort_by = Tie::IxHash->new(@$sort_by)
			if ref $sort_by eq 'ARRAY';
		$q->{'query'} = $query;
		$q->{'orderby'} = $sort_by;
	} else {
		$q = $query ? $query : {};
	}

	my $conn_key = version->parse($MongoDB::VERSION) < v0.502.0 ? '_connection' : '_client';

	my $cursor = MongoDBx::Class::Cursor->new(
		$conn_key => $self->_database->_connection,
		_ns => $self->full_name, 
		_query => $q, 
		_limit => $limit, 
		_skip => $skip
	);

	$cursor->_init;

	return $cursor;
};

sub search {
	shift->find(@_);
}

=head2 find_one( $query, [ \%fields ] )

Performs a query on the collection and returns the first matching document.

This method is modified in the following way:

1. In L<MongoDB::Collection>, C<$query> can either be a hash-ref, a
L<Tie::IxHash> object or an array-ref. Here, however, C<$query> can also
be a MongoDB::OID, or a MongoDB::OID's string representation (see L<MongoDB::OID/"to_string">).
Searching by internal ID is thus much more convenient:

	my $doc = $coll->find_one("4cbca90d3a41e35916720100");

2. The matching document is automatically expanded to the appropriate
document class, but only if it has the '_class' attribute (as described
in L<MongoDBx::Class/"CAVEATS AND THINGS TO CONSIDER">). If it doesn't, or if expansion is
impossible due to other reasons, it will be returned as is (i.e. as a
hash-ref).

3. In MongoDB::Collection, passing a C<\%fields> hash-ref will result in
the document being returned with those fields only (and the _id field).
Behavior of this when documents are expanded is currently undefined.

=cut

around 'find_one' => sub {
	my ($orig, $self, $orig_query, $fields) = @_;

	my $query = {};

	if ($orig_query && !ref $orig_query && length($orig_query) == 24) {
		$query->{_id} = MongoDB::OID->new(value => $orig_query);
	} elsif ($orig_query && ref $orig_query eq 'MongoDB::OID') {
		$query->{_id} = $orig_query;
	} elsif ($orig_query) {
		$query = $orig_query;
	}

	return $self->$orig($query, $fields);
};

=head2 insert( $doc, [ \%opts ] )

Inserts the given document into the database, automatically collapsing
it before insertion.

An optional options hash-ref can be passed. If this hash-ref holds a safe
key with a true value, insert will be safe (refer to L<MongoDB::Collection/"insert ($object, $options?)">
for more information). When performing a safe insert, the newly created
document is returned (after expansions). If unsafe, its L<MongoDB::OID>
is returned.

If your L<connection object|MongoDBx::Class::Connection> has a true value
for the safe attribute, insert will be safe by default. If that is the case,
and you want the specific insert to be unsafe, pass a false value for
C<safe> in the C<\%opts> hash-ref.

Document to insert can either be a hash-ref, a L<Tie::IxHash> object or
an even-numbered array-ref, but currently only hash-refs are automatically
collapsed.

=head2 batch_insert( \@docs, [ \%opts ] )

Receives an array-ref of documents and an optional hash-ref of options,
and inserts all the documents to the collection one after the other. C<\%opts>
can have a "safe" key that should hold a boolean value. If true (and if
your L<connection object|MongoDB::Connection> has a true value for the
safe attribute), inserts will be safe, and an array of all the documents
inserted (after expansion) will be returned. If false, an array with all
the document IDs is returned.

Documents to insert can either be hash-refs, L<Tie::IxHash> objects or
even-numbered array references, but currently only hash-refs are automatically
collapsed.

=cut

around 'batch_insert' => sub {
	my ($orig, $self, $docs, $opts) = @_;

	$opts ||= {};
	$opts->{safe} = 1 if $self->_database->_connection->safe && !defined $opts->{safe};

	foreach (@$docs) {
		next unless ref $_ eq 'HASH' && $_->{_class};
		$_ = $self->_database->_connection->collapse($_);
	}

	if ($opts->{safe}) {
		return map { $self->find_one($_) } $self->$orig($docs, $opts);
	} else {
		return $self->$orig($docs, $opts);
	}
};

=head2 update( \%criteria, \%object, [ \%options ] )

Searches for documents matching C<\%criteria> and updates them according
to C<\%object> (refer to L<MongoDB::Collection/"update (\%criteria, \%object, \%options?)">
for more info). As opposed to the original method, this method will
automatically collapse the C<\%object> hash-ref. It will croak if criteria
and/or object aren't hash references.

Do not use this method to update a specific document that you already
have (i.e. after expansion). L<MongoDBx::Class::Document> has its own
update method which is more convenient.

Notice that this method doesn't collapse attributes with the
L<Parsed|MongoDBx::Class::Meta::AttributeTraits> trait. Only the
L<MongoDBx::Class::Document> update method performs that.

=cut

around 'update' => sub {
	my ($orig, $self, $criteria, $object, $opts) = @_;

	croak 'Criteria for update must be a hash reference (received '.ref($criteria).').'
		unless ref $criteria eq 'HASH';

	croak 'Object for update must be a hash reference (received '.ref($object).').'
		unless ref $object eq 'HASH';

	$self->_collapse_hash($object);

	return $self->$orig($criteria, $object, $opts);
};

=head2 ensure_index( $keys, [ \%options ] )

Makes sure the given keys of this collection are indexed. C<$keys> is either
an unordered hash-ref, an ordered L<Tie::IxHash> object, or an ordered,
even-numbered array reference like this:

	$coll->ensure_index([ title => 1, date => -1 ])

=cut

around 'ensure_index' => sub {
	my ($orig, $self, $keys, $options) = @_;

	if ($keys && ref $keys eq 'ARRAY') {
		$keys = Tie::IxHash->new(@$keys);
	}

	return $self->$orig($keys, $options);
};

=head1 INTERNAL METHODS

The following methods are only to be used internally:

=head2 _collapse_hash( \%object )

Collapses an entire hash-ref for proper database insertions.

=cut

sub _collapse_hash {
	my ($self, $object) = @_;

	foreach (keys %$object) {
		if (m/^\$/ && ref $object->{$_} eq 'HASH') {
			# this is something like '$set' or '$inc', we need to collapse the values in it
			$self->_collapse_hash($object->{$_});
		} else {
			$object->{$_} = $self->_database->_connection->_collapse_val($object->{$_});
		}
	}
}

=head1 AUTHOR

Ido Perlmuter, C<< <ido at ido50.net> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-mongodbx-class at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=MongoDBx-Class>. I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

	perldoc MongoDBx::Class::Collection

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=MongoDBx::Class>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/MongoDBx::Class>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/MongoDBx::Class>

=item * Search CPAN

L<http://search.cpan.org/dist/MongoDBx::Class/>

=back

=head1 SEE ALSO

L<MongoDB::Collection>.

=head1 LICENSE AND COPYRIGHT

Copyright 2010-2014 Ido Perlmuter.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut

__PACKAGE__->meta->make_immutable;
