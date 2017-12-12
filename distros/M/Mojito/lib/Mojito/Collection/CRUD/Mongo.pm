use strictures 1;
package Mojito::Collection::CRUD::Mongo;
$Mojito::Collection::CRUD::Mongo::VERSION = '0.25';
use MongoDB::OID;
use 5.010;
use Moo;
use Syntax::Keyword::Junction qw/ any /;
use Data::Dumper::Concise;

with('Mojito::Role::DB::Mongo');

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

    my $collection = $self->collection->find_one({ collection_name  => $params->{collection_name} });
    my $oid;
    if ( $oid = $collection->{_id} ) {
        $self->collection->update( { '_id' => $oid }, $params );
    } 
    else {
        $oid = $self->collection->insert($params);
    }
    
    return $oid->value;
}

=head2 read

Read a collection from the database.

=cut

sub read {
    my ( $self, $id ) = @_;
    my $oid = MongoDB::OID->new( value => $id );
    return $self->collection->find_one( { _id => $oid } );
}

=head2 update

Update a collection in the database.

=cut

sub update {
    my ( $self, $params) = @_;

    my $oid = MongoDB::OID->new( value => $params->{id} );
    $params->{last_modified} = time();

    $self->collection->update( { '_id' => $oid }, $params );
}

=head2 delete

Delete a collection from the database.

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

=head2 collection_for_page

Get all the collection ids for which this page is a member of.

=cut

sub collections_for_page {
    my ($self, $page_id) = @_;

    # NOTE: For some yet to be determined reason I could not
    # pass {collected_page_ids => $page_id} to $self->collection->find();
    my $collections = $self->get_all; 
    my @collection_ids;
    while (my $doc = $collections->next) {
        my @collected_pages = @{$doc->{collected_page_ids}};
        if ($page_id eq any(@collected_pages)) {
            push @collection_ids, $doc->{_id}->value ;
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
    # Have we assigned the page to at least one collection?
    if (defined $collection_ids->[0]) {
        my $cursor = $self->db->collection->find({collected_page_ids => $params->{mongo_id}});
        my %HAVE;
        while (my $collection = $cursor->next) {
            $HAVE{$collection->{_id}} = 1;
        }
        my %WANT = map { $_ => 1 } @{$collection_ids};
        # collection_id of zero in this case means we don't want to assign
        # the page to any collection
        %WANT = () if not $collection_ids->[0];
        foreach my $collection_id (keys %WANT) {
            if (not $HAVE{$collection_id}) {
            # add page_id to the collection
                my $collection = $self->collector->read($collection_id);
                push @{$collection->{collected_page_ids}}, $params->{mongo_id};
                my $oid = MongoDB::OID->new( value => $collection_id );
                $self->db->collection->update({_id => $oid}, $collection);
            }
        }
        foreach my $collection_id (keys %HAVE) {
            if (not $WANT{$collection_id}) {
            # remove the page_id from the collection
                my $oid = MongoDB::OID->new( value => $collection_id );
                $self->db->collection->update(
                    { _id => $oid },
                    { '$pull' => {collected_page_ids => $params->{mongo_id} } },
                );
            }
        }
    }
    
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
