use strictures 1;
package Mojito::Page::CRUD::Deep;
$Mojito::Page::CRUD::Deep::VERSION = '0.25';
use 5.010;
use Moo;
use Data::Dumper::Concise;

with('Mojito::Role::DB::Deep');

has base_url => ( is => 'rw', );

=head1 Name

Mojito::Page::CRUD::Deep - DBM::Deep CRUD

=head1 Methods

=head2 create

Create a page in the database.

=cut

sub create {
    my ( $self, $page_struct ) = @_;

    # add save time as last_modified and created
    $page_struct->{last_modified} = $page_struct->{created} = time();
    my $oid = $self->generate_mongo_like_oid;
    $page_struct->{id} = $oid;

    # Is this sucker used ja?
    # TODO: Seek out another when generated one is already used.
    die "oid: $oid is already in use" if ($self->collection && $self->collection->exists($oid));
    # If the collection does not exist yet let's initialize it.
    if (!$self->collection) {
        $self->db->{$self->collection_name} = {};
    }
    $self->collection->{$oid} = $page_struct;
    
    return $oid;
}

=head2 read

Read a page from the database.

=cut

sub read {
    my ($self, $id) = @_;
    die "No id passed" if !$id;
    if ($self->collection->{$id}) {
        return $self->collection->{$id}->export;  
    }
    return;
}

=head2 update

Update a page in the database.

=cut

sub update {
    my ( $self, $id, $page_struct ) = @_;
    $page_struct->{last_modified} = time();
    # Add in id as a key/value
    $page_struct->{id} = $id;
    $self->collection->{$id} = $page_struct;
}

=head2 delete

Delete a page from the database.

=cut

sub delete {
    my ( $self, $id ) = @_;
    $self->collection->delete($id);
}

=head2 get_all

Get all pages in the notes collection.
Returns a MongoDB cursor one can iterate over.

=cut

sub get_all {
    my $self = shift;
    return $self->collection->export;
}

1
