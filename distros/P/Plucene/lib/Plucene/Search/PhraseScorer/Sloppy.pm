package Plucene::Search::PhraseScorer::Sloppy;

=head1 NAME

Plucene::Search::PhraseScorer::Sloppy - sloppy phrase scorer

=head1 SYNOPSIS

	# isa Plucene::Search::PhraseScorer

=head1 DESCRIPTION

This is a sloppy phrase scorer

=head1 METHODS

=cut

use strict;
use warnings;

use List::Util qw(max);

use base 'Plucene::Search::PhraseScorer';

__PACKAGE__->mk_accessors(q{slop});

sub _phrase_freq {
	my $self = shift;
	my $end  = 0;
	$#{ $self->{pq} } = -1;
	my $pp = $self->first;
	while ($pp) {
		$pp->first_position;
		$end = max($end, $pp->position);
		push @{ $self->{pq} }, $pp;
		$pp = $pp->next_in_list;
	}

	my $freq = 0;
	my $done = 0;
	do {
		my $pp    = shift @{ $self->{pq} };
		my $start = $pp->position;
		my $next  = $self->{pq}->[0]->position;
		for (my $pos = $start ; $pos <= $next ; $pos = $pp->position) {
			$start = $pos;
			if (!$pp->next_position) {
				$done = 1;
				last;
			}
		}

		my $length = $end - $start;
		$freq += 1 / ($length + 1) if $length <= $self->slop;
		$end = max($end, $pp->position);
		push @{ $self->{pq} }, $pp;
	} while (!$done);
	return $freq;
}

1;
