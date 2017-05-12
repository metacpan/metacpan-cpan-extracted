use strictures 1;
package Mojito::Collection::CRUD::Elasticsearch;
{
  $Mojito::Collection::CRUD::Elasticsearch::VERSION = '0.24';
}
use MongoDB::OID;
use 5.010;
use Moo;
use List::Util qw/first/;
use Syntax::Keyword::Junction qw/ any /;
use Elasticsearch::Scroll; 
use Data::Dumper::Concise;

with('Mojito::Role::DB::Elasticsearch');

has base_url => ( is => 'rw', );

=head1 Methods

=head2 create

Create a list of document ids in the collection named 'collection'.
The funny name is due to the fact we're storing document ids from
the notes collection in individual documents of the collection collection.
i.e. we are creating (ordered) sets of documents identified with
a document name.

The motivation for collections of docs collection is so that we can group 
documents together form display purposes.  Form example, say I'm working 
on a project with multiple documents.  I'd like to be able to "identify/tag" 
them to the project so I can narrow my viewing focus to just those documents.

=cut

sub create {
    my ( $self, $params ) = @_;

    # We don't need to store the form submit value
    delete $params->{collect};
    my $page_ids = $params->{collected_page_ids};
    
    # NOTE: The $page_ids input can come in two different forms: 
    # - String:   "$page_id1,$page_id2,...$page_id_n";
    # - ArrayRef: [$page_id1,$page_id2,..., $page_id_n];
    $params->{collected_page_ids} = [split ',', $page_ids] if (!ref($page_ids));
    
    # add save time as last_modified and created
    $params->{last_modified} = $params->{created} = time();

    my $collection_struct = $self->collection->{hits}{hits};
    my @collections = map { $_->{_source} } @{$collection_struct};
    my $collection = first { $_->{collection_name} eq $params->{collection_name} } @collections;
    $params->{id} = 
         $collection->{_id} 
      || $collection->{id} 
      || $self->generate_mongo_like_oid;
    $self->db->index(
        index => $self->db_name,
        type  => $self->collection_name,
        id    => $params->{id}, 
        body  => $params,
    );
    return $params->{id};
}

=head2 read

Read a collection from the database.

=cut

sub read {
    my ( $self, $id ) = @_;
    my $doc = $self->db->get_source(
        index => $self->db_name,
        type => $self->collection_name,
        id => $id,
    );
    return $doc;
}

=head2 update

Update a collection in the database.

=cut

sub update {
    my ( $self, $id, $params) = @_;

    $params->{last_modified} = time();
    $self->db->update(
        index => $self->db_name,
        type  => $self->collection_name,
        id    => $id,
        body  =>  { doc => $params },
    );
}

=head2 delete

Delete a collection from the database.

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
    return $self->collection->{hits}{hits};
}

=head2 collection_for_page

Get all the collection ids for which this page is a member of.

=cut

sub collections_for_page {
    my ( $self, $page_id ) = @_;

    $page_id //= '';
    my @collection_ids = ();
    my @collections = map { $_->{_source} } @{$self->get_all};
    foreach my $collection (@collections) {
        if ($page_id eq any(@{$collection->{collected_page_ids}})) {
            push @collection_ids, $collection->{id};
        }
    }

    return @collection_ids;
}

sub update_collection_membership {
    my ($self, $params) = @_;

    my $collection_ids = $params->{collection_select};
     # Want to coerce (single select) SCALAR into an ArrayRef (happens w/ Dancer params)
    if (ref($collection_ids) ne 'ARRAY') {
        warn "Coercing collection select params into an ArrefRef" if $ENV{MOJITO_DEBUG};
        $collection_ids = [$collection_ids];
    }

    my $scroll = Elasticsearch::Scroll->new(
        es => $self->db,
        search_type => 'scan',
        index => $self->db_name,
        type  => $self->collection_name,
        body => {query => {term => {collected_page_ids => $params->{mongo_id}}}},
    );
    my %HAVE;
    while (my $collection = $scroll->next) {
        $HAVE{$collection->{_source}{id}} = 1;
    }
    my %WANT = map { $_ => 1 } @{$collection_ids};
    foreach my $collection_id (keys %WANT) {
        if (not $HAVE{$collection_id}) {
        # add page_id to the collection
            my $collection = $self->read($collection_id);
            push @{$collection->{collected_page_ids}}, $params->{mongo_id};
            $self->update($collection_id, $collection);
        }
    }
    foreach my $collection_id (keys %HAVE) {
        if (not $WANT{$collection_id}) {
            # remove the page_id from the collection
            my $collection = $self->read($collection_id);
            my @collected_page_ids = grep { $_ ne $params->{mongo_id} }
              @{$collection->{collected_page_ids}};
            $self->update(
                $collection_id, 
                {collected_page_ids => \@collected_page_ids},
            );
        }
    }

    return;
}
=head2 BUILD

Set the collection we want to work with.
In this case it's the collection named 'collection'.
It's a bit meta is why the funny naming.

=cut

sub BUILD {
    my $self = shift;
    $self->collection_name('collection');
}

1
