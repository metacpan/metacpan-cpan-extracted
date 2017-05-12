package Plucene::Search::BooleanQuery;

=head1 NAME 

Plucene::Search::BooleanQuery - a boolean query

=head1 SYNOPSIS

	# isa Plucene::Search::Query

	$query->add(Plucene::Search::Query $query, $required, $prohibited);
	$query->normalize($norm);
	
	my        @clauses = $query->clauses;
	my $sum_sq_weights = $query->sum_squared_weights($searcher);
	my      $as_string = $query->to_string($field);
	
=head1 DESCRIPTION

A query that matches documents matching boolean combinations of 
other queries, typically TermQuerys or PhraseQuery

A boolean query represents a composite query that may contains subqueries 
of arbitrary nesting level and with composition rules such as 'and', 
'or' or 'not'.

Boolean queries are represented in Plucene API by instances of the 
BooleanQuery class. Each BooleanQuery object contains a list of subqueries 
that are linked using instances of the adaptor class BooleanClause. The 
subqueries may be of any Query type such as term query, phrase query and 
nested boolean queries.

Each sub query of a boolean query has two binary qualifiers that controls 
how its super query is matched. These qualifiers are

=over 4

=item * prohibited - when this flag is set, the matching status of the 
subquery is negated such that the query is considered as a match only 
when the sub query does not match.
 
=item * required - when this flag is set, the sub query is required to match 
(or not to match if its 'prohibited' flag is set) for the super query 
to match.  This this is a necessary but not sufficient condition for the 
super query to match. 

=back

=head1 METHODS

=cut

use strict;
use warnings;

use List::Util qw(sum);

use Plucene::Search::BooleanClause;
use Plucene::Search::BooleanScorer;

use base "Plucene::Search::Query";

__PACKAGE__->mk_accessors(qw(clauses));

=head2 add

	$query->add(Plucene::Search::Query $query, $required, $prohibited);

Adds a clause to a boolean query.  Clauses may be:

=over 

=item required 

which means that documents which I<do not> match this sub-query will
I<not> match the boolean query;

=item prohibited

which means that documents which I<do> match this sub-query will I<not> match
the boolean query; or

=item

neither, in which case matched documents are neither prohibited from
nor required to match the sub-query.

=back

It is an error to specify a clause as both required and prohibited.

=cut

sub add {
	my ($self, $query, $required, $prohibited) = @_;
	push @{ $self->{clauses} },
		Plucene::Search::BooleanClause->new({
			query      => $query,
			required   => ($required || 0),
			prohibited => ($prohibited || 0) });
}

=head2 add_clause

	$self->add_clause(Plucene::Search::BooleanClause $c);
	
Adds an already-formed clause onto the query.

=cut

sub add_clause {
	my ($self, $clause) = @_;
	push @{ $self->{clauses} }, $clause;
}

=head2 clauses

	my @clauses = $query->clauses;

=cut

sub clauses { @{ shift->{clauses} } }

sub prepare {
	my ($self, $reader) = @_;
	$_->query->prepare($reader) for $self->clauses;
}

=head2 sum_squared_weights

	my $sum_sq_weights = $query->sum_squared_weights($searcher);

=cut

sub sum_squared_weights {
	my ($self, $searcher) = @_;
	sum map $_->query->sum_squared_weights($searcher), grep !$_->prohibited,
		$self->clauses;
}

=head2 normalize

	$query->normalize($norm);

=cut

sub normalize {
	my ($self, $norm) = @_;
	$_->query->normalize($norm) for grep !$_->prohibited, $self->clauses;
}

sub _scorer {
	my ($self, $reader) = @_;
	my @clauses = $self->clauses;
	if (@clauses == 1) {
		my $c = $clauses[0];
		return $c->query->_scorer($reader) unless $c->prohibited;
	}

	my $result = Plucene::Search::BooleanScorer->new();
	for my $c ($self->clauses) {
		my $subscorer = $c->query->_scorer($reader);
		if ($subscorer) {
			$result->add($subscorer, $c->required, $c->prohibited);
		} else {

			# If it was required and we didn't score, kill it.
			return if $c->required;
		}
	}

	return $result;
}

=head2 to_string

	my $as_string = $query->to_string($field);

=cut

sub to_string {
	my ($self, $field) = @_;
	join " ", map {
		my $buffer;
		$buffer .= "-" if $_->prohibited;
		$buffer .= "+" if $_->required;
		my $q = $_->query;
		if ($q->isa(__PACKAGE__)) {
			$buffer .= "(" . $q->to_string($field) . ")";
		} else {
			$buffer .= $q->to_string($field);
		}
		$buffer;
	} $self->clauses;
}

1;
