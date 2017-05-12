package Plucene::Search::Searcher;

=head1 NAME 

Plucene::Search::Searcher - base class for searchers

=head1 DESCRIPTION

Abstract base class for searchers.

Searching is the operation of locating a subset of the documents that 
contains desired content or that their attributes match some specification.

The input for a search operation is a 'query' that specifies a criteria for 
selecting the documents and its output is a list of documents ('hits') that 
matched that criteria.

The hit list is typically ordered by some measure of relevancy (called 
'ranking' or 'scoring') and may contain only a subset of the set of documents 
that matched the query (typically the ones with the highest scored documents).

The search operation is performed on an 'index' which is a specialized 
database that contains a pre compiled information of the document set. 
The index database is optimized for locating quickly documents that contains 
certain words or terms. 

=head1 METHODS

=cut

use strict;
use warnings;

use Plucene::Search::Hits;

=head2 doc_freq / max_doc / doc / _search_hc search_top

These must be defined in a subclas

=cut

sub doc_freq   { die "doc_freq must be defined in a subclass" }
sub max_doc    { die "max_doc must be defined in a subclass" }
sub doc        { die "doc must be defined in a subclass" }
sub _search_hc { die "_search_hc must be defined in a subclass" }
sub search_top { die "search_top must be defined in a subclass" }

=head2 search

	my Plucene::Search::Hits $hits = $searcher->new($query, $filter);

This will return the Plucene::Search::Hits object for the passed in query
and filter. At this stage, filter is optional.

=cut

sub search {
	my ($self, $query, $filter) = @_;

	# $filter may be undefined, that's OK
	return Plucene::Search::Hits->new({
			searcher => $self,
			query    => $query,
			filter   => $filter
		});
}

=head2 search_hc

=cut

sub search_hc {
	my ($self, $query, $hc) = @_;
	$self->_search_hc($query, undef, $hc);
}

1;
