use strictures 1;
package Mojito::Model::Doc::Deep;
{
  $Mojito::Model::Doc::Deep::VERSION = '0.24';
}
use Moo;
use Data::Dumper::Concise;

with('Mojito::Role::DB::Deep');

=head1 Methods

=head2 get_most_recent_docs

{ 
    id1 => {}, 
    id2 => {} 
}

=cut

sub get_most_recent_docs {
    my ($self) = @_;
    return [] if !$self->collection;
    my $docs = $self->collection->export;
    my @sorted_docs;
    foreach my $id (
        sort { 
            $docs->{$a}->{last_modified} <=> $docs->{$b}->{last_modified} 
        } keys %{$docs}
    ) {
        push @sorted_docs, $docs->{$id};
    }
    return [@sorted_docs];
}

=head2 get_feed_docs

Get the documents for a particular feed sorted by date in reverse chrono order.
Returns a cursor to them.

=cut

sub get_feed_docs {
    my ($self, $feed) = @_;
    return [] if !$self->collection;
    my $collection = $self->collection->export;
    my @docs = values %{$collection}; 
    my @feed_docs = grep { $_->{feeds} && $_->{feeds} eq $feed } @docs;
    @feed_docs = sort { $a->{last_modified} <=> $b->{last_modified} } @feed_docs;
    return \@feed_docs; 
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
    return [] if !$self->collection;
    my $collections = $self->collection->export;
    my @sorted_collections;
    foreach my $id (
        sort { 
            $collections->{$a}->{last_modified} <=> $collections->{$b}->{last_modified} 
        } keys %{$collections}
    ) {
        push @sorted_collections, $collections->{$id};
    }
    return [@sorted_collections];
}

=head2 get_collection_pages

Get the pages belonging to a particular collection.
NOTE: We get the list of page ids from the collection collected_page_ids value.
Then we find all documents corresponding to those ids.

Return an (collection_name, ArrayRef of pages);
=cut

sub get_collection_pages {
    my ($self, $collection_id) = @_; 

    $self->clear_collection_name;
    $self->clear_collection;
    $self->collection_name('collection');
    my $collection = $self->collection->{$collection_id}->export;
    my $page_ids = $collection->{collected_page_ids};
    # Change to notes collection
    $self->clear_collection_name;
    $self->clear_collection;
    $self->collection_name('notes');
    my @pages;
    foreach my $id (@{$page_ids}) {
        my $page = $self->collection->{$id};
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
    my $docs = $self->collection->export;
    my @docs = grep { ($_->{last_modified} >= $start_epoch) && ($_->{last_modified} <= $end_epoch) } values %{$docs};
    foreach my $doc (@docs) {
        my $day = DateTime->from_epoch(epoch => $doc->{last_modified})->day;
        push @{ $monthly_data{$day} },
          { id => $doc->{id}, title => $doc->{title} };
    }
    return %monthly_data;
}

1;