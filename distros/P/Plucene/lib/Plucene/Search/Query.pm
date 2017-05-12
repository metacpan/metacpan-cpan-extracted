package Plucene::Search::Query;

=head1 NAME 

Plucene::Search::Query - base class for queries

=head1 SYNOPSIS

	my $s_query = Plucene::Search::Query::Subclass->new({
		boost => $boost_factor});

	my $scorer = $s_query->scorer($query, $searcher, $reader);

=head1 DESCRIPTION

This is an abstract base class for queries.

A query is a specification of the content an properties of the desired 
documents. Every search is done by matching a query against the document 
index and locating the ones that match the query.

The simplest query specifies a single term (or word) that is to be matched 
against a single field (e.g. 'author') of each of the documents in the index. 
This kind of query matches any document that contains the term in the 
specified field.

A more complex queries may contain nested queries with 'and', 'or', 'not' 
or 'phrase' relations. Queries may also contains specification of which 
document fields to match against the various parts of the query 
(.e.g.  'authors' and 'title') and hints that may effects the ranking of 
the matched documents ('boost' factor).

=head1 METHODS

=cut

use strict;
use warnings;

use base qw/Class::Accessor::Fast/;
__PACKAGE__->mk_accessors(qw/boost/);

=head2 new

	my $s_query = Plucene::Search::Query::Subclass->new({
		boost => $boost_factor});

=head2 boost

Get / set this attribute

=cut

sub new {
	my ($self, $opts) = @_;
	$opts->{boost} = 1 unless exists $opts->{boost};
	$self->SUPER::new($opts);
}

=head2 scorer

	my $scorer = $s_query->scorer
		(Plucene::Search::Query $query, $searcher, $reader);

=cut

sub scorer {
	my ($class, $query, $searcher, $reader) = @_;

	$query->prepare($reader);
	my $sum = $query->sum_squared_weights($searcher) || 1;
	my $norm = 1 / sqrt($sum);
	$query->normalize($norm);
	return $query->_scorer($reader);
}

=head2 prepare

Does nothing

=head2 sum_squared_weights / normalize  / _scorer

These must be defined in a subclass

=cut

sub prepare { }

sub sum_squared_weights {
	die "sum_squared_weights must be defined in a subclass";
}
sub normalize { die "normalize must be defined in a subclass" }
sub _scorer   { die "_scorer must be defined in a subclass" }

1;
