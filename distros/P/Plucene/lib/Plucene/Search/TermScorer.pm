package Plucene::Search::TermScorer;

=head1 NAME 

Plucene::Search::TermScorer - score terms

=head1 SYNOPSIS

	# isa Plucene::Search::Scorer

	$term_scorer->score($hc, $end);
	
=head1 DESCRIPTION

This is a Plucene::Search::Scorer subclass for scoring terms.

=head1 METHODS

=cut

use strict;
use warnings;

use constant SCORE_CACHE_SIZE => 32;

use Plucene::Search::Similarity;

use base qw(Plucene::Search::Scorer Class::Accessor::Fast);

=head2 term_docs / norms / weight / doc / docs / freqs / pointer / 
	pointer_max / score_cache

Get / set these attributes

=cut

__PACKAGE__->mk_accessors(
	qw(term_docs norms weight doc docs freqs
		pointer pointer_max score_cache)
);

sub new {
	my $self = shift->SUPER::new(@_);
	$self->weight(1) unless $self->weight();
	$self->_compute_score_cache;
	$self->_refill_buffers;
	return $self;
}

sub _compute_score_cache {
	my $self = shift;
	for (0 .. SCORE_CACHE_SIZE - 1) {
		$self->{score_cache}[$_] =
			Plucene::Search::Similarity->tf($_) * $self->weight;
	}
}

sub _refill_buffers {
	my $self = shift;
	$self->pointer(0);
	my ($docs, $freqs) = $self->{term_docs}->read;
	$self->docs($docs);
	$self->freqs($freqs);
	$self->pointer_max(scalar @$docs);
	if ($self->{pointer_max} > 0) {
		$self->doc($docs->[0]);
	} else {
		$self->doc(~0);
	}    # Sentinel
}

=head2 score

	$term_scorer->score($hc, $end);

=cut

sub score {
	my ($self, $hc, $end) = @_;
	my $d = $self->doc;
	while ($d < $end) {
		my $f = $self->{freqs}->[ $self->{pointer} ];
		$self->_score_it($f, $d, $hc);

		if (++$self->{pointer} == $self->{pointer_max}) {
			$self->_refill_buffers;
			return if $self->doc == ~0;
		}
		$d = $self->{docs}[ $self->{pointer} ];
	}
	$self->doc($d);
}

1;
