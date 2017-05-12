package Plucene::Search::PhraseQuery;

=head1 NAME 

Plucene::Search::PhraseQuery - A query that matchs a phrase

=head1 SYNOPSIS

	# isa Plucene::Search::Query

=head1 DESCRIPTION

A Query that matches documents containing a particular sequence of terms.

A phrase query represents a query that is matched against a consecutive 
sequence of terms in the field. For example, the phrase query 'winding road' 
should match 'winding road' but not 'road winding' (with the exception of 
more relaxed slop factors).

Phrase queries are represented in Plucene's API by instances of the 
PharseQuery class.  These instances contain an ordered list of Term objects 
that represent the terms to match. For obvious reasons, all terms in a 
PhraseQuery must refer to the same field.

A phrase query may have an optional boost factor and an optional slop 
parameter (default = 0). The slop parameter can be used to relax the phrase 
matching by accepting somewhat out of order sequences of the terms. 

=head1 METHODS

=cut

use strict;
use warnings;

use Carp;

use Plucene::Search::Similarity;
use Plucene::Search::TermQuery;
use Plucene::Search::TermScorer;
use Plucene::Search::PhraseScorer::Exact;
use Plucene::Search::PhraseScorer::Sloppy;

use base 'Plucene::Search::Query';

__PACKAGE__->mk_accessors(qw(slop terms field idf weight));

sub new {
	my $self = shift->SUPER::new(@_);
	$self->slop(0);
	$self->terms([]);
	$self;
}

=head2 add

Adds a term to the end of the query phrase.

=cut

sub add {
	my ($self, $term) = @_;
	if (@{ $self->terms } == 0) {
		$self->field($term->field);
	} elsif ($self->field ne $term->field) {
		carp "All terms in this phrase should be in the same field: "
			. $self->field;
	}
	push @{ $self->terms }, $term;
}

=head2 sum_squared_weights

The sum squared weights of this query.

=cut

sub sum_squared_weights {
	my ($self, $searcher) = @_;
	$self->{idf} += Plucene::Search::Similarity->idf($_, $searcher)
		for @{ $self->terms };
	$self->{weight} = $self->idf * $self->boost;
	$self->boost * $self->boost;
}

=head2 normalize

Normalize the query.

=cut

sub normalize {
	my ($self, $norm) = @_;
	$self->{weight} *= $norm * $self->idf;
}

sub _scorer {
	my ($self, $reader) = @_;
	return unless @{ $self->{terms} };
	if (@{ $self->{terms} } == 1) {
		my $term = $self->{terms}->[0];
		my $docs = $reader->term_docs($term);
		return unless $docs;
		return Plucene::Search::TermScorer->new({
				term_docs => $docs,
				norms     => $reader->norms($term->field),
				weight    => $self->weight
			});
	}

	my @tps;
	for my $term (@{ $self->terms }) {
		my $tp = $reader->term_positions($term);
		return unless $tp;
		push @tps, $tp;
	}

	my $class =
		"Plucene::Search::PhraseScorer::"
		. (($self->slop == 0) ? "Exact" : "Sloppy");
	$class->new({
			tps    => \@tps,
			norms  => $reader->norms($self->field),
			weight => $self->weight,
			slop   => $self->slop
		});
}

=head2 to_string

Prints a user-readable version of this query.

=cut

sub to_string {
	my ($self, $field) = @_;
	my $buffer = "";
	$buffer = $self->field . ":" if $field ne $self->field;
	$buffer .= sprintf('"%s"', join(" ", map $_->text, @{ $self->terms }));
	$buffer .= "~" . $self->slop  if $self->slop;
	$buffer .= "^" . $self->boost if $self->boost != 1;
	$buffer;
}

1;
