package MongoDBx::Class::Reference;

# ABSTRACT: An embedded document representing a reference to a different document (thus establishing a relationship)

our $VERSION = "1.030002";
$VERSION = eval $VERSION;

use Moose;
use namespace::autoclean;
use Carp;

=head1 NAME

MongoDBx::Class::Reference - An embedded document representing a reference to a different document (thus establishing a relationship)

=head1 VERSION

version 1.030002

=head1 CONSUMES

L<MongoDBx::Class::EmbeddedDocument>

=head1 DESCRIPTION

This class represents a reference (or "join") to a MongoDB document.
In L<MongoDBx::Class>, references are expected to be in the DBRef format,
as defined in L<http://www.mongodb.org/display/DOCS/Database+References>,
for example (this is a JSON example):

	{ "$ref": "collection_name", "$id": ObjectId("4cbca90d3a41e35916720100") }

=cut

with 'MongoDBx::Class::EmbeddedDocument';

=head1 ATTRIBUTES

Aside from attributes provided by L<MongoDBx::Class::EmbeddedDocument>,
the following attributes are provided:

=head2 ref_coll

A string representing the collection in which the reference document is
stored (translates to the '$ref' hash key above).

=head2 ref_id

A L<MongoDB::OID> object with the internal ID of the referenced document
(translates to the '$id' hash key above).

=cut

has 'ref_coll' => (is => 'ro', isa => 'Str', required => 1);

has 'ref_id' => (is => 'ro', isa => 'MongoDB::OID', required => 1);

=head1 METHODS

Aside from methods provided by L<MongoDBx::Class::EmbeddedDocument>,
the following methods are provided:

=head2 load()

Returns the document referenced by this object, after expansion. This is
mostly used internally, you don't have to worry about it.

=cut

sub load {
	my $self = shift;

	return $self->_collection->_database->get_collection($self->ref_coll)->find_one($self->ref_id);
}

=head1 AUTHOR

Ido Perlmuter, C<< <ido at ido50.net> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-mongodbx-class at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=MongoDBx-Class>. I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

	perldoc MongoDBx::Class::Reference

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

L<MongoDBx::Class::EmbeddedDocument>.

=head1 LICENSE AND COPYRIGHT

Copyright 2010-2014 Ido Perlmuter.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut

__PACKAGE__->meta->make_immutable;
