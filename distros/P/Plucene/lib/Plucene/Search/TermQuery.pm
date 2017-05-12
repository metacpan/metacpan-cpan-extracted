package Plucene::Search::TermQuery;

=head1 NAME 

Plucene::Search::TermQuery - a query that contains a term

=head1 SYNOPSIS

	# isa Plucene::Search::Query

	$term_query->normalize($norm);

	my       $ssw = $term_query->sum_squared_weights($searcher);
	my $as_string = $term_query->as_string($field);

=head1 DESCRIPTION

A query that matches a document containing a term.

Term query are the simplest possible Plucene queries and are used to match a 
single word. Term queries are represented by instances of the TermQuery class 
and contain the desired term (word) and a field name, both are case sensitive.

The field specified in a Term query must be a document field that was specified 
as 'indexible' during the indexing process. If the field was specified during 
indexing as 'tokenized' than the term will be matched against each of tokens 
(words) found in that field, otherwise, it will be matched against the entire 
content of that field.

A term query may have an optional boost factor (default = 1.0) that allows to 
increase or decrease the ranking of documents it matches.

=head1 METHODS

=cut

use strict;
use warnings;

use Plucene::Index::Reader;
use Plucene::Search::Similarity;
use Plucene::Search::TermScorer;

use base 'Plucene::Search::Query';

=head2 term / idf / weight

Get / set these attributes

=cut

__PACKAGE__->mk_accessors(qw(term idf weight));

=head2 sum_squared_weights

	my $ssw = $term_query->sum_squared_weights($searcher);

This will return the sum squared weights for the passed in searcher.

=cut

sub sum_squared_weights {
	my ($self, $searcher) = @_;
	$self->idf(Plucene::Search::Similarity->idf($self->term, $searcher));
	$self->weight($self->idf * $self->boost);
	return $self->{weight}**2;
}

=head2 normalize

	$term_query->normalize($norm);

=cut

sub normalize {
	my ($self, $norm) = @_;
	$self->{weight} *= $norm;
	$self->{weight} *= $self->{idf};
}

sub _scorer {
	my ($self, $reader) = @_;
	my $term_docs = $reader->term_docs($self->term);
	return unless $term_docs;
	my $norms = $reader->norms($self->term->field);
	return unless $norms;
	return Plucene::Search::TermScorer->new({
			term_docs => $term_docs,
			norms     => $norms,
			weight    => $self->{weight} });
}

=head2 to_string

	my $as_string = $term_query->as_string($field);

=cut

sub to_string {
	my ($self, $field) = @_;
	my $rv = "";
	$rv = $self->term->field . ":" if $field ne $self->term->field;
	$rv .= $self->term->text;
	$rv .= "^" . $self->boost unless $self->boost == 1;
	return $rv;
}

1;
