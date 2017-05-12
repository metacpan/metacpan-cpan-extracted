package Plucene::Search::IndexSearcher;

=head1 NAME 

Plucene::Search::IndexSearcher - The index searcher

=head1 SYNOPSIS

	# isa Plucene::Search::Searcher

	my $searcher = Plucene::Search::IndexSearcher
		->new(Plucene::Index::Reader $reader);

	my Plucene::Index::Reader $reader = $searcher->reader;
	my         Plucene::Document $doc = $reader->doc($id);

	$searcher->close;
	
=head1 DESCRIPTION

Search over an IndexReader

=head1 METHODS

=cut

use strict;
use warnings;

use Bit::Vector::Minimal;
use Carp;

use Plucene::Index::Reader;
use Plucene::Search::HitCollector;
use Plucene::Search::Query;
use Plucene::Search::TopDocs;

use base 'Plucene::Search::Searcher';

=head2 new

	my $searcher = Plucene::Search::IndexSearcher
		->new(Plucene::Index::Reader $reader);

This will create a new Searcher object with the passed Plucene::Index::Reader
or subclass thereof.
		
=cut

sub new {
	my ($self, $thing) = @_;
	if (not ref $thing and -d $thing) {
		$thing = Plucene::Index::Reader->open($thing);
	}
	croak "Don't know how to turn $thing into an index reader"
		unless UNIVERSAL::isa($thing, "Plucene::Index::Reader");
	bless { reader => $thing }, $self;
}

=head2 reader

	my Plucene::Index::Reader $reader = $searcher->reader;

This will return the reader this searcher was made with.

=head2 search_top

The top search results.

=head2 doc

	my Plucene::Document $doc = $reader->doc($id);

This will return the Plucene::Document $id.

=head2 doc_freq / max_doc

get / set these

=cut

sub doc_freq { shift->reader->doc_freq(@_) }
sub max_doc  { shift->reader->max_doc(@_) }

sub reader { shift->{reader} }

sub doc { shift->reader->document(@_); }

sub search_top {
	my ($self, $query, $filter, $n_docs) = @_;
	my $scorer = Plucene::Search::Query->scorer($query, $self, $self->{reader});
	return Plucene::Search::TopDocs->new({ total_hits => 0, score_docs => [] })
		unless $scorer;
	my $bits = $filter && $filter->bits($self->{reader});

	# This is the hitqueue class, essentially
	tie my @hq, "Tie::Array::Sorted", sub {
		my ($hit_a, $hit_b) = @_;
		return ($hit_a->{score} <=> $hit_b->{score})
			|| ($hit_b->{doc} <=> $hit_a->{doc});
	};
	my $total_hits = 0;    # Dunno why this is an array in Java

	# This is where it turns ugly
	$scorer->score(
		Plucene::Search::HitCollector->new(
			collect => do {
				my $min_score = 0;
				sub {
					my ($self, $doc, $score) = @_;
					return
						if $score == 0
						|| ($bits && !$bits->get($doc));
					$total_hits++;
					if ($score >= $min_score) {
						push @hq, { doc => $doc, score => $score };
						if (@hq > $n_docs) {
							shift @hq;
							$min_score = $hq[0]->{score};
						}
					}
					}
				}
		),
		$self->{reader}->max_doc
	);

	my @array = @hq;    # Copy out of tied array
	return Plucene::Search::TopDocs->new({
			total_hits => $total_hits,
			score_docs => \@array
		});
}

sub _search_hc {
	my ($self, $query, $filter, $results) = @_;
	my $collector = $results;
	if ($filter) {
		my $bits = $filter->bits($self->{reader});
		$collector = Plucene::Search::HitCollector->new(
			collect => sub {
				$results->collect(@_) if $bits->get($_[0]);
			});
	}

	my $scorer = Plucene::Search::Query->scorer($query, $self, $self->{reader});
	return unless $scorer;
	$scorer->score($collector, $self->{reader}->max_doc);
}

=head2 close

This will close the reader(s) associated with the searcher.

=cut

sub close { shift->{reader}->close }

1;
