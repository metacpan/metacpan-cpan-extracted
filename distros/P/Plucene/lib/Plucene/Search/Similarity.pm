package Plucene::Search::Similarity;

=head1 NAME 

Plucene::Search::Similarity - the score of a query

=head1 DESCRIPTION

The score of a query for a given document.

=head1 METHODS

=cut

use strict;
use warnings;

use Carp qw(confess);
use POSIX qw(ceil);

=head2 norm

	my $norm = $sim->norm($num_term);

=cut

sub norm {
	my ($self, $num_terms) = @_;
	return 0 if not defined $num_terms or $num_terms == 0;
	return ceil(255 / sqrt($num_terms));
}

=head2 byte_norm

	my $byte_norm = $sim->byte_norm($byte);

=cut

sub byte_norm {
	my ($self, $byte) = @_;
	ord($byte) / 255;
}

=head2 tf

Computes a score factor based on a term or phrase's frequency in a document.

=cut

sub tf { my $self = shift; return sqrt(shift); }

=head2 idf

Computes a score factor for a phrase.

=cut

sub idf {
	my ($self, $tf, $docs) = @_;
	my ($x, $y) = ($docs->doc_freq($tf), $docs->max_doc);
	return 1 + log($y / (1 + $x));
}

=head2 coord

Computes a score factor based on the fraction of all query terms that 
a document contains.

=cut

sub coord { my ($self, $a, $b) = @_; $a / $b }    # Duh.

1;
