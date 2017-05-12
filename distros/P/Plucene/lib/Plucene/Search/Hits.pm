package Plucene::Search::Hits;

=head1 NAME 

Plucene::Search::Hits - A list of ranked documents

=head1 SYNOPSIS

	my $hits = Plucene::Search::Hits->new;

	my     $doc = $hits->doc($n);
	my   $score = $hits->score($n);
	my $hit_doc = $hits->hit_doc($n);
	
=head1 DESCRIPTION

This is a list of ranked documents, used to hold search results.

=head1 METHODS

=cut

use strict;
use warnings;

use Carp qw/croak/;

use Plucene::Search::TopDocs;

use base 'Class::Accessor::Fast';
__PACKAGE__->mk_accessors(
	qw/ query searcher filter length hit_docs
		first last num_docs max_docs /
);

=head2 new

	my $hits = Plucene::Search::Hits->new;

=head2 query / searcher / filter / length / hit_docs / first / 
	last / num_docs / max_docs

Get / set these attributes.

=cut

sub new {
	my $self = shift->SUPER::new(@_);
	$self->num_docs(0);
	$self->max_docs(200);
	$self->hit_docs([]);
	$self->_get_more_hits(50);
	return $self;
}

sub _get_more_hits {
	my ($self, $min) = @_;
	if (@{ $self->{hit_docs} } > $min) { $min = @{ $self->{hit_docs} }; }
	my $n = $min * 2;
	my $top_docs = $self->searcher->search_top($self->query, $self->filter, $n);
	$self->length($top_docs->total_hits);

	my @score_docs = $top_docs->score_docs;

	my $score_norm = 1.0;
	$score_norm = 1 / $score_docs[0]->{score}
		if $self->length > 0
		and $score_docs[0]->{score} > 1.0;

	my $end = $#score_docs < $self->length ? $#score_docs : $self->length;
	for my $score_doc (@score_docs[ @{ $self->{hit_docs} } .. $end ]) {
		push @{ $self->{hit_docs} },
			Plucene::Search::HitDoc->new({
				score => $score_doc->{score} * $score_norm,
				id    => $score_doc->{doc},
			});
	}
}

=head2 doc

	my $doc = $hits->doc($n);

Returns the nth document.
	
=cut

sub doc {
	my ($self, $n) = @_;
	my $hit = $self->hit_doc($n);

	# Not sure we need the LRU for now

	return $hit->doc || $hit->doc($self->searcher->doc($hit->id));
}

=head2 score

	my $score = $hits->score($n);

The score of the nth document.
	
=cut

sub score {
	my ($self, $n) = @_;
	return $self->hit_doc($n)->score;
}

=head2 hit_doc

	my $hit_doc = $hits->hit_doc($n);

Returns the nth hit document.

=cut

sub hit_doc {
	my ($self, $n) = @_;
	if ($n >= $self->length) {
		croak("Not a valid hit number: $n");
	}
	$self->_get_more_hits($n) if $n >= @{ $self->{hit_docs} };
	return $self->{hit_docs}[$n];
}

package Plucene::Search::HitDoc;

use base 'Class::Accessor::Fast';

__PACKAGE__->mk_accessors(qw/score id doc/);

1;
