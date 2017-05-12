package Plucene::Index::SegmentsTermEnum;

=head1 NAME

Plucene::Index::SegmentsTermEnum

=head1 METHODS

=head2 new / term / doc_freq / next 

as per TermEnum

=cut

# This only appears to be used with doing wildcard searches.

use strict;
use warnings;

use Tie::Array::Sorted;
use Plucene::Index::SegmentMergeInfo;

sub term     { $_[0]->{term} }
sub doc_freq { $_[0]->{doc_freq} }

sub new {
	my ($class, $readers, $starts, $t) = @_;

	tie my @queue, "Tie::Array::Sorted";
	for my $i (0 .. $#{$readers}) {
		my $reader    = $readers->[$i];
		my $term_enum = $reader->terms($t);
		my $smi       =
			Plucene::Index::SegmentMergeInfo->new($starts->[$i], $term_enum,
			$reader);
		if (!$t ? $smi->next : $term_enum->term) {    # ???
			push @queue, $smi;
		}
	}
	my $self = bless { queue => \@queue }, $class;
	if ($t and @queue) {
		my $top = $queue[0];
		$self->{term}     = $top->term_enum->term;
		$self->{doc_freq} = $top->term_enum->doc_freq;
	}
	return $self;
}

sub next {
	my $self = shift;
	my $top  = $self->{queue}[0];
	if (!$top) {
		undef $self->{term};
		return;
	}

	$self->{term}     = $top->term;
	$self->{doc_freq} = 0;
	while ($top && $self->{term}->eq($top->term)) {
		$self->{doc_freq} += $top->term_enum->doc_freq;

		# This might look funny, but it's right. The pop takes $top off
		# the queue, and when it has ->next called on it, its comparison
		# value changes; the queue is tied as a Tie::Array::Sorted, so
		# when it gets added back on, it may be put somewhere else.
		pop @{ $self->{queue} };
		if ($top->next) {
			unshift @{ $self->{queue} }, $top;
		}
		$top = $self->{queue}[0];
	}
	return 1;
}

1;
