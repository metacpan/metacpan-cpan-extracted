package MongoDBx::AutoDeref::DBRef;
BEGIN {
  $MongoDBx::AutoDeref::DBRef::VERSION = '1.110560';
}

#ABSTRACT: DBRef representation in Perl

use Moose;
use namespace::autoclean;
use MooseX::Types::Moose(':all');


has mongo_connection =>
(
    is => 'ro',
    isa => 'MongoDB::Connection',
    required => 1,
);


has '$id' =>
(
    is => 'ro',
    isa => 'MongoDB::OID',
    reader => 'id',
    required => 1,
);


has '$ref' =>
(
    is => 'ro',
    isa => Str,
    reader => 'ref',
    required => 1,
);


has '$db' =>
(
    is => 'ro',
    isa => Str,
    reader => 'db',
    required => 1,
);


has lookmeup =>
(
    is => 'ro',
    isa => 'MongoDBx::AutoDeref::LookMeUp',
    required => 1,
    weak_ref => 1,
);


sub revert
{
    my ($self) = @_;
    return +{ '$db' => $self->db, '$ref' => $self->ref, '$id' => $self->id };
}


sub fetch
{
    my ($self, $fields) = @_;
    my %hash = %{$self->revert()};
    my @dbs = $self->mongo_connection->database_names();
    die "Database '$hash{'$db'}' doesn't exist"
        unless (scalar(@dbs) > 0 || any(@dbs) eq $hash{'$db'});

    my $db = $self->mongo_connection->get_database($hash{'$db'});
    my @cols = $db->collection_names;

    die "Collection '$hash{'$ref'}' doesn't exist in $hash{'$db'}"
        unless (scalar(@cols) > 0 || any(@cols) eq $hash{'$ref'});

    my $collection = $db->get_collection($hash{'$ref'});

    my $doc = $collection->find_one
    (
        {
            _id => $hash{'$id'}
        },
        (
            defined($fields)
                ? $fields
                : ()
        )
    ) or die "Unable to find document with _id: '$hash{'$id'}'";

    $self->lookmeup->sieve($doc);
    return $doc;
}

__PACKAGE__->meta->make_immutable();
1;


=pod

=head1 NAME

MongoDBx::AutoDeref::DBRef - DBRef representation in Perl

=head1 VERSION

version 1.110560

=head1 DESCRIPTION

MongoDBx::AutoDeref::DBRef is the Perl space representation of Mongo database
references. These ideally shouldn't be constructed manually, but instead should
be constructed by the internal L<MongoDBx::AutoDeref::LookMeUp> class. 

=head1 PUBLIC_ATTRIBUTES

=head2 mongo_connection

    is: ro, isa: MongoDB::Connection, required: 1

In order to defer fetching the referenced document, a connection object needs to
be accessible. This is required for construction of the object.

=head2 $id

    is: ro, isa: MongoDB::OID, reader: id, required: 1

This is the OID of the object.

=head2 $ref

    is: ro, isa: Str, reader: ref, required: 1

This is the collection in which this item resides.

=head2 $db

    is: ro, isa: Str, reader: db, required: 1

This is the database in which this item resides.

=head2 lookmeup

    is: ro, isa: MongoDBx::AutoDeref::LookMeUp, weak_ref: 1, required: 1

When fetching referenced documents, those documents may in turn reference other
documents. By providing a LookMeUp object, those other references can also be
travered as DBRefs.

=head1 PUBLIC_METHODS

=head2 revert

This method returns a hash reference in the DBRef format suitable for MongoDB
serialization.

=head2 fetch

    (HashRef?)

fetch takes the information contained in the L</$db>, L</$ref>, L</$id>
attributes and applies them via the L</mongo_connection> to retrieve the
document that is referenced.

fetch also accepts a hashref of fields-as-keys that will be passed unaltered
directly to the MongoDB driver as a way to limit the fields pulled back.

=head1 AUTHOR

Nicholas R. Perez <nperez@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by Nicholas R. Perez <nperez@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut


__END__

