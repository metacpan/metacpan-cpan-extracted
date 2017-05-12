package Plucene::Search::BooleanScorer;

=head1 NAME 

Plucene::Search::BooleanScorer - A boolean scorer

=head1 SYNOPSIS

	# isa Plucene::Search::Scorer

	$bool_scorer->add($scorer, $required, $prohibited);
	$bool_scorer->score($results, $max_doc);

=head1 DESCRIPTION

This is a scoring class for boolean scorers.

=head1 METHODS

=cut

use strict;
use warnings;

use List::Util qw(min);

use Plucene::Search::Similarity;

use base qw(Plucene::Search::Scorer Class::Accessor::Fast);

__PACKAGE__->mk_accessors(
	qw(next_mask required_mask prohibited_mask max_coord scorers bucket_table
		coord_factors current_doc)
);

=head2 new

	my $bool_scorer = Plucene::Search::BooleanScorer->new;

Create a new Plucene::Search::BooleanScorer object.

=head2 next_mask / required_mask / prohibited_mask max_coord / scorers / 
	bucket_table / coord_factors / current_doc

Get / set these attributes

=cut

sub new {
	my $self = shift->SUPER::new(@_);
	$self->max_coord(1);
	$self->next_mask(1);
	$self->current_doc(0);
	$self->required_mask(0);
	$self->prohibited_mask(0);
	$self->scorers([]);
	$self->bucket_table(Plucene::Search::BucketTable->new({ scorer => $self }));
	return $self;
}

=head2 add

	$bool_scorer->add($scorer, $required, $prohibited);

=cut

sub add {
	my ($self, $scorer, $required, $prohibited) = @_;
	my $mask = 0;
	if ($required || $prohibited) {
		$mask = $self->next_mask;
		$self->{next_mask} <<= 1;
	}

	$self->{max_coord}++ unless $prohibited;

	$self->{prohibited_mask} |= $mask if $prohibited;
	$self->{required_mask}   |= $mask if $required;
	push @{ $self->{scorers} },
		{
		scorer     => $scorer,
		required   => $required,
		prohibited => $prohibited,
		collector  => $self->bucket_table->new_collector($mask) };
}

sub _compute_coord_factors {
	my $self = shift;
	$self->coord_factors([
			map Plucene::Search::Similarity->coord($_, $self->max_coord),
			0 .. $self->max_coord
		]);
}

=head2 score

	$bool_scorer->score($results, $max_doc);

=cut

sub score {
	my ($self, $results, $max_doc) = @_;
	$self->_compute_coord_factors if not defined $self->coord_factors;
	while ($self->current_doc < $max_doc) {
		$self->current_doc(
			min(
				$self->{current_doc} + $Plucene::Search::BucketTable::SIZE, $max_doc
			));
		for my $t (@{ $self->{scorers} }) {
			$t->{scorer}->score($t->{collector}, $self->current_doc);
		}
		$self->bucket_table->collect_hits($results);
	}
}

package Plucene::Search::BucketTable;
our $SIZE = 1 << 10;
our $MASK = $SIZE - 1;

use base 'Class::Accessor::Fast';
__PACKAGE__->mk_accessors(qw(buckets first scorer));

sub new {
	my $self = shift->SUPER::new(@_);
	$self->buckets([]);
	$self;
}

sub collect_hits {
	my ($self, $results) = @_;
	my $scorer     = $self->scorer;
	my $required   = $scorer->required_mask;
	my $prohibited = $scorer->prohibited_mask;
	my @coord      = @{ $scorer->coord_factors };

	for (my $bucket = $self->{first} ; $bucket ; $bucket = $bucket->{next}) {
		if (  ($bucket->{bits} & $prohibited) == 0
			and ($bucket->{bits} & $required) == $required) {
			$results->collect($bucket->{doc},
				$bucket->{score} * $coord[ $bucket->{coord} ]);
		}
	}
	undef $self->{first};
}

sub new_collector {
	my ($self, $mask) = @_;
	return Plucene::Search::BucketCollector->new({
			bucket_table => $self,
			mask         => $mask
		});
}

package Plucene::Search::BucketCollector;
use base (qw(Class::Accessor::Fast Plucene::Search::HitCollector));

__PACKAGE__->mk_accessors(qw(bucket_table mask));

sub collect {
	my ($self, $doc, $score) = @_;
	my $table  = $self->{bucket_table};
	my $i      = $doc & $Plucene::Search::BucketTable::MASK;
	my $bucket = $table->buckets->[$i];
	$table->buckets->[$i] = $bucket = {} unless $bucket;

	if (not defined $bucket->{doc} or $bucket->{doc} != $doc) {
		@{$bucket}{qw(doc    score  bits         coord)} =
			($doc, $score, $self->{mask}, 1);
		$bucket->{next} = $table->first;
		$table->first($bucket);
	} else {
		$bucket->{score} += $score;
		$bucket->{bits} |= $self->{mask};
		$bucket->{coord}++;
	}
}

1;

