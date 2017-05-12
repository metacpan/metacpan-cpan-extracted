package Plucene::Search::Scorer;

=head1 NAME 

Plucene::Search::Scorer - base class for scorers

=head1 DESCRIPTION

Abstract base class for scoring.

=cut

use strict;
use warnings;

use Plucene::Search::Similarity;

=head2 score

This must be defined in a subclass

=cut

sub score { die "score must be defined in a subclass" }

sub _score_it {
	my ($self, $freq, $doc, $results) = @_;
	return unless $freq > 0;
	my $score     = Plucene::Search::Similarity->tf($freq) * $self->weight;
	my $norm      = substr($self->norms, $doc, 1);
	my $norm_freq = Plucene::Search::Similarity->byte_norm($norm);
	$score *= $norm_freq;
	$results->collect($doc, $score);
}

1;
