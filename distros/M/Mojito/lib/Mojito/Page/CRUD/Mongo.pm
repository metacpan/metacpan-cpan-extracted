use strictures 1;
package Mojito::Page::CRUD::Mongo;
$Mojito::Page::CRUD::Mongo::VERSION = '0.25';
use MongoDB::OID;
use 5.010;
use Moo;
use Data::Dumper::Concise;

with('Mojito::Role::DB::Mongo');

has base_url => ( is => 'rw', );

=head1 Name

Mojito::Page::CRUD::Mongo - MongoDB CRUD

=head1 Methods

=head2 create

Create a page in the database.

=cut

sub create {
    my ( $self, $page_struct ) = @_;

    # Add created (and last_modified) timestamps
    # If page struct has a created let's use that instead
    # under the assumption we're loading outside data. e.g. from MojoMojo
    my $now = time();
    $page_struct->{created} //= $now;
    $page_struct->{last_modified} //= $now;
    my $id = $self->collection->insert($page_struct);

    return $id->value;
}

=head2 read

Read a page from the database.

=cut

sub read {
    my ( $self, $id ) = @_;
    my $oid = MongoDB::OID->new( value => $id );
    return $self->collection->find_one( { _id => $oid } );
}

=head2 update

Update a page in the database.

=cut

sub update {
    my ( $self, $id, $page_struct ) = @_;

    my $oid = MongoDB::OID->new( value => $id );
    $page_struct->{last_modified} = time();
    $self->collection->update( { '_id' => $oid }, $page_struct );
}

=head2 delete

Delete a page from the database.

=cut

sub delete {
    my ( $self, $id ) = @_;

    my $oid = MongoDB::OID->new( value => $id );
    $self->collection->remove( { '_id' => $oid } );
}

=head2 get_all

Get all pages in the notes collection.
Returns a MongoDB cursor one can iterate over.

=cut

sub get_all {
    my $self = shift;
    return $self->collection->find;
}

1;