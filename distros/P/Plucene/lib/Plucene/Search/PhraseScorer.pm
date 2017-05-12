package Plucene::Search::PhraseScorer;

=head1 NAME 

Plucene::Search::PhraseScorer - a phrase scorer

=head1 SYNOPSIS

	# isa Plucene::Search::Scorer

	$scorer->score($results, $end);
	
=head1 DESCRIPTION

This is the phrase scorer.

=head1 METHODS

=cut

use strict;
use warnings;

use Tie::Array::Sorted;

use Plucene::Search::PhrasePositions;

use base qw(Plucene::Search::Scorer Class::Accessor::Fast);

sub _phrase_freq { die "Abstract method" }

__PACKAGE__->mk_accessors(qw/ norms weight pq first last /);

sub new {
	my $self = shift->SUPER::new(@_);
	my @pq;
	tie @pq, "Tie::Array::Sorted", sub {
		$_[0]->doc <=> $_[1]->doc
			|| $_[0]->position <=> $_[1]->position;
	};

	for my $i (0 .. $#{ $self->{tps} }) {
		push @pq,
			Plucene::Search::PhrasePositions->new({
				tp     => $self->{tps}->[$i],
				offset => $i
			});
	}

	$self->{pq} = \@pq;

	$self->_pq_to_list();
	return $self;
}

# Thread the array elements together into a linked list
sub _pq_to_list {
	my $self = shift;
	$self->{first} = $self->{last} = undef;
	while (@{ $self->{pq} }) {
		my $pp = shift @{ $self->{pq} };

		# If there's an entry already, put this after it
		if ($self->{last}) { $self->last->next_in_list($pp); }

		# Else, this is the first one
		else { $self->first($pp); }

		# But it's definitely the last one
		$self->last($pp);

		# And there's nothing after it, yet.
		$pp->next_in_list(undef);
	}
}

=head2 score

	$scorer->score($results, $end);
	
=cut

sub score {
	my ($self, $results, $end) = @_;
	while ($self->last->doc < $end) {
		while ($self->first->doc < $self->last->doc) {
			do {
				$self->first->next;
			} while $self->first->doc < $self->last->doc;
			$self->_first_to_last;
			return if $self->last->doc >= $end;
		}
		my $freq = $self->_phrase_freq;
		$self->_score_it($freq, $self->first->doc, $results);
		$self->last->next;
	}
}

sub _first_to_last {
	my $self = shift;
	$self->last->next_in_list($self->first);
	$self->last($self->first);
	$self->first($self->first->next_in_list);
	$self->last->next_in_list(undef);
}

1;
