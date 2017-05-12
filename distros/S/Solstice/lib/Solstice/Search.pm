package Solstice::Search;

=head1 SYNOPSIS

my $search = Some::Model::Package->createSearch('puppies');

#multiple filters broaden the selection - we'll match
#brown OR grey pets
$search->addFilter('color', $brown);
$search->addFilter('size', $grey);

# must be used only on fields that were set to be stored and vectorized
# the hits will now have an "excerpt" key with html bolded matches
$search->setExcerptField('body'); 

my $hit_iter = $search->getHits()->iterator(); #all hits
#or
my $hit_iter = $search->getHits(0,9)->iterator(); #first ten hits

while( my $hit = $hit_iter->next() ){
    ...
}

=over 4

=cut

use strict;
use warnings;
use 5.006_000;

use base qw(Solstice);

use constant TRUE  => 1;
use constant FALSE => 0;

sub _init {
    my $self = shift;
    $self->{'_query'} = shift;
    $self->{'_searcher'} = shift;
    $self->{'_search_ran'} = FALSE;
}

=item addFilter ($field, $value)

Requires hits to match the given value in the given field.

Multiple filters can be added - only one has to match.

=cut

sub addFilter {
    my ($self, $field, $value) = @_;

    return unless $field && $value && ($self->{'_search_ran'} == FALSE);

    #get the filter
    my $filter;
    if($self->{'_filter'}){
        $filter = $self->{'_filter'};
    }else{
        $filter = $self->{'_filter'} = KinoSearch::Search::BooleanQuery->new();
    }


    #preare this filter clause
    my $filter_query = KinoSearch::Search::TermQuery->new(
        term => KinoSearch::Index::Term->new( $field, $value),
    );

    $filter->add_clause( query => $filter_query, occur => 'SHOULD' );

    return TRUE;
}


=item setExcerptField ($field_name)

Causes the hits to include an 'excerpt' key that contains a snippet of the
searched text with the matches wrapped in HTML bold tags.

This must only be called for fields that were set to be vectorized and stored.

=cut

sub setExcerptField {
    my ($self, $excerpt_field) = @_;

    return unless $excerpt_field;

    $self->{'_excerpt_field'} = $excerpt_field;
}


=item getHits ([$first, $last])

Returns a Solstice::List of hits.  The optional first/last params will cause
a subset of the hits to be returned.

=cut

sub getHits {
    my ($self, $first, $last) = @_;


    my $hits;
    unless( $self->{'_search_ran'} ){
        $self->{'_search_ran'} = TRUE;

        if ($self->{'_filter'}){
            $hits = $self->{'_searcher'}->search( 
                query => $self->{'_query'}, 
                filter =>  KinoSearch::Search::QueryFilter->new( query => $self->{'_filter'} 
                )
            );
        } else {
            $hits = $self->{'_searcher'}->search( query => $self->{'_query'} );
        }
        $self->{'_hits'} = $hits;

    }else{
        $hits = $self->{'_hits'};
    }

    if($self->{'_excerpt_field'}){
        my $highlighter = KinoSearch::Highlight::Highlighter->new( 
            excerpt_field  => $self->{'_excerpt_field'},
            encoder        => 'Solstice::Search',
        );
        $hits->create_excerpts( highlighter => $highlighter );
    }

    if(defined $first && defined $last && ($self->_isValidPositiveInteger($first) || $first == 0) && $self->_isValidPositiveInteger($last)){
        $hits->seek($first, $last);
    }else {
        $hits->seek(0,$hits->total_hits);
    }

    my $list = Solstice::List->new();
    while ( my $hit = $hits->fetch_hit_hashref ) {
        $list->add($hit);
    }
    return $list;
}

=item encode

This is here to short-circuit the search libraries attempt to encode html entities.
It is a no-op.

=cut

sub encode {
    my $self = shift;
    return shift;
}

1;

=back

=head1 COPYRIGHT

Copyright 1998-2007 Office of Learning Technologies, University of Washington

Licensed under the Educational Community License, Version 1.0 (the "License");
you may not use this file except in compliance with the License. You may obtain
a copy of the License at: http://www.opensource.org/licenses/ecl1.php

Unless required by applicable law or agreed to in writing, software distributed
under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
CONDITIONS OF ANY KIND, either express or implied.  See the License for the
specific language governing permissions and limitations under the License.

=cut
