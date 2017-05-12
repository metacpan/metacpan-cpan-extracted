use strictures 1;
package Mojito::Page::CRUD::Elasticsearch;
{
  $Mojito::Page::CRUD::Elasticsearch::VERSION = '0.24';
}
use 5.010;
use Moo;

with('Mojito::Role::DB::Elasticsearch');

has base_url => ( is => 'rw', );

=head1 Name

Mojito::Page::CRUD::ES - Elasticsearch CRUD

=head1 Methods

=head2 create

Create a page in the database.

=cut

sub create {
    my ( $self, $page_struct ) = @_;
    $page_struct->{last_modified} = $page_struct->{created} = time();
    my $oid = $self->generate_mongo_like_oid;
    $page_struct->{id} = $oid;
    $self->db->index(
        index => $self->db_name,
        type  => $self->collection_name,
        id    => $oid, 
        body  => $page_struct,
    );
    return $oid;
}

=head2 read

Read a page from the database.

=cut


sub read {
    my ($self, $id) = @_;
    die "No id passed" if !$id;

    my $doc;
    unless (
        eval { 
            $doc = $self->db->get_source(
                index => $self->db_name,
                type => $self->collection_name,
                id => $id,
            ); 1;
        }
    ) {
        warn "WARNING: Document with id: $id not found";
    }

    return $doc;
}

=head2 update

Update a page in the database.

=cut

sub update {
    my ( $self, $id, $page_struct ) = @_;
    $page_struct->{last_modified} = time();
    # Add in id as a key/value
    $page_struct->{id} = $id;
    $self->db->update(
        index => $self->db_name,
        type  => $self->collection_name,
        id    => $id,
        body  =>  { doc => $page_struct },
    );
}

=head2 delete

Delete a page from the database.

=cut

sub delete {
    my ( $self, $id ) = @_;
    $self->db->delete(
        index => $self->db_name,
        type  => $self->collection_name,
        id    => $id,
        refresh => 1,
    );
}

=head2 get_all

Get all pages in the notes collection.
Returns an ArrayRef

=cut

sub get_all {
    my $self = shift;
    return $self->collection->{hits}{hits};
}

1
