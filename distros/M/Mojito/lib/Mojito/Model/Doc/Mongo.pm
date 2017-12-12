use strictures 1;
package Mojito::Model::Doc::Mongo;
$Mojito::Model::Doc::Mongo::VERSION = '0.25';
use Moo;
use MongoDB::OID;
use Data::Dumper::Concise;

with('Mojito::Role::DB::Mongo');

=head1 Methods

=head2 get_most_recent_docs

Get the documents sorted by date in reverse chrono order.
Returns a cursor to them.

=cut

sub get_most_recent_docs {
    my $self = shift;
    return $self->collection->find->sort( { last_modified => -1 } );
}

=head2 get_feed_docs

Get the documents for a particular feed sorted by date in reverse chrono order.
Returns a cursor to them.

=cut

sub get_feed_docs {
    my ($self, $feed) = @_;
    return $self->collection->find({feeds => $feed})->sort( { last_modified => -1 } );
}

=head2 get_collections

Get the collections by name sorted by date in reverse chrono order.
Returns a cursor to them.

=cut

sub get_collections {
    my $self = shift;
    $self->clear_collection_name;
    $self->clear_collection;
    $self->collection_name('collection');
    return $self->collection->find->sort( { last_modified => -1 } );
}

=head2 get_collection_pages

Get the pages belonging to a particular collection.
NOTE: We get the list of page ids from the collection collected_page_ids value.
Then we find all documents corresponding to those ids.

Return an (collection_name, ArrayRef of pages);
=cut

sub get_collection_pages {
    my ($self, $collection_id) = (shift, shift);


    $self->clear_collection_name;
    $self->clear_collection;
    $self->collection_name('collection');
    my $oid = MongoDB::OID->new( value => $collection_id );
    my $collection = $self->collection->find_one( { _id => $oid } );
    my $page_ids = $collection->{collected_page_ids};
    my @page_oids = map { MongoDB::OID->new( value => $_ ) } @{$page_ids};
    
    # Change to notes collection
    $self->clear_collection_name;
    $self->clear_collection;
    $self->collection_name('notes');
    my @pages;
    foreach my $oid (@page_oids) {
        my $page =  $self->collection->find_one( { _id => $oid } );
        push @pages, $page;
    }
   return ($collection->{collection_name}, \@pages); 
}

sub get_docs_for_month {
    my ($self, $month, $year) = @_;

    my %monthly_data = ();
    my $start_epoch  = DateTime->new(
        year   => $year,
        month  => $month,
        day    => 1,
        hour   => 0,
        minute => 0,
        second => 0,
    )->epoch;
    my $next_month         = ($month == 12) ? 1         : $month + 1;
    my $year_of_next_month = ($month == 12) ? $year + 1 : $year;
    my $end_epoch          = DateTime->new(
        year   => $year_of_next_month,
        month  => $next_month,
        day    => 1,
        hour   => 0,
        minute => 0,
        second => 0,
    )->epoch;
    my $docs = $self->collection->find(
        { 'last_modified' => { '$gte' => $start_epoch, '$lt' => $end_epoch } });
    while (my $doc = $docs->next) {
        my $day = DateTime->from_epoch(epoch => $doc->{last_modified})->day;
        push @{ $monthly_data{$day} },
          { id => $doc->{_id}->value, title => $doc->{title} };
    }
    return %monthly_data;
}

1

__END__
    my $oid = MongoDB::OID->new( value => $id );
    return $self->collection->find_one( { _id => $oid } );
