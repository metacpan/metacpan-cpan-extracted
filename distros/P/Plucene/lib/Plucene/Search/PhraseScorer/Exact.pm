package Plucene::Search::PhraseScorer::Exact;

=head1 NAME 

Plucene::Search::PhraseScorer::Exact - exact phrase scorer

=head1 SYNOPSIS

	# isa Plucene::Search::PhraseScorer

=head1 DESCRIPTION

This is the eact phrase scorer

=cut

use strict;
use warnings;

use base 'Plucene::Search::PhraseScorer';

sub _phrase_freq {
	my $self = shift;
	my $pp   = $self->first;
	while ($pp) {
		$pp->first_position;
		push @{ $self->{pq} }, $pp;
		$pp = $pp->next_in_list;
	}

	$self->_pq_to_list;

	my $freq = 0;
	do {
		while ($self->first->position < $self->last->position) {
			do {
				return $freq unless $self->first->next_position;
			} while $self->first->position < $self->last->position;
			$self->_first_to_last;
		}
		$freq++;
	} while $self->last->next_position;
	return $freq;
}

1;
