package Plucene::Search::TopDocs;

=head1 NAME 

Plucene::Search::TopDocs - The top hits for a query

=head1 SYNOPSIS

	my $total_hits = $top_docs->total_hits;
	my @score_docs = $top_docs->score_docs(@other);

=head1 DESCRIPTION

=head1 METHODS

=head2 total_hits

	my $total_hits = $top_docs->total_hits;

The total number of hits for the query.

=cut

use strict;
use warnings;

use base 'Class::Accessor::Fast';

__PACKAGE__->mk_accessors(qw/ total_hits score_docs /);

=head2 score_docs

	my @score_docs = $top_docs->score_docs(@other);

The top hits for the query.

=cut

sub score_docs {
	my ($self, @other) = @_;
	if (@other) { $self->{score_docs} = [@other] }
	@{ $self->{score_docs} };
}

1;
