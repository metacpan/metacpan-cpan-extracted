use strictures 1;
package Mojito::Model::Doc::Elasticsearch;
{
  $Mojito::Model::Doc::Elasticsearch::VERSION = '0.24';
}
use Moo;
use Data::Dumper::Concise;

with('Mojito::Role::DB::Elasticsearch');

=head1 Methods

=head2 get_most_recent_docs

=cut

sub get_most_recent_docs {
    my ($self) = @_;
    return [] if !$self->collection;
    my $docs = $self->collection->{hits}{hits};
    my @docs = map { $_->{_source} } @{$docs};
    my @sorted_docs = sort { 
            $b->{last_modified} <=> $a->{last_modified} 
    } @docs;
    return [@sorted_docs];
}

=head2 get_feed_docs

Get the documents for a particular feed sorted by date in reverse chrono order.

=cut

sub get_feed_docs {
    my ($self, $feed) = @_;
    return [] if !$self->collection;
    my $collection = $self->collection;
    my @docs = map { $_->{_source} } @{$collection->{hits}{hits}}; 
    my @feed_docs = grep { $_->{feeds} && $_->{feeds} eq $feed } @docs;
    @feed_docs = sort { $b->{last_modified} <=> $a->{last_modified} } @feed_docs;
    return \@feed_docs; 
}

=head2 get_collections

Get the collections by name sorted by date in reverse chrono order.

=cut

sub get_collections {
    my $self = shift;
    
    $self->clear_collection_name;
    $self->clear_collection;
    $self->collection_name('collection');
    return [] if !$self->collection;
    my $collections = $self->collection->{hits}{hits};
    my @collections = map { $_->{_source} } @{$collections};
    my @sorted_collections = sort { 
            $b->{last_modified} <=> $a->{last_modified} 
    } @collections;

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
    my $collection;
    unless (
        eval { 
            $collection = $self->db->get_source(
                index => $self->db_name,
                type => $self->collection_name,
                id => $collection_id,
            ); 1;
        }) {
        warn "WARNING: Collection with id: $collection_id not found";
        return;
    }
    my $page_ids = $collection->{collected_page_ids};
    # Change to notes collection
    $self->clear_collection_name;
    $self->clear_collection;
    $self->collection_name('notes');
    my @pages;
    foreach my $id (@{$page_ids}) {
        my $page;
        unless ( eval { 
            $page = $self->db->get_source(
                index => $self->db_name,
                type  => $self->collection_name,
                id    => $id,
            ); 1;
        }) {
            warn "WARNING: Collection with id: $id not found";
            next;
        }
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
    my $docs = $self->collection->{hits}{hits};
    my @docs = map { $_->{_source} } @{$docs};
    @docs = grep { ($_->{last_modified} >= $start_epoch) && ($_->{last_modified} <= $end_epoch) } @docs;
    @docs = sort { $b->{last_modified} <=> $a->{last_modified} } @docs;
    foreach my $doc (@docs) {
        my $day = DateTime->from_epoch(epoch => $doc->{last_modified})->day;
        push @{ $monthly_data{$day} },
          { id => $doc->{id}, title => $doc->{title} };
    }
    return %monthly_data;
}

1;
