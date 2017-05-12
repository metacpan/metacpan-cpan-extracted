package Plucene::Search::PrefixQuery;

=head1 NAME 

Plucene::Search::TermQuery - a query that matches terms beginning with a string

=head1 SYNOPSIS

	# isa Plucene::Search::Query

	$prefix_query->normalize($norm);

	my       $ssw = $prefix_query->sum_squared_weights($searcher);
	my $as_string = $prefix_query->to_string($field);

=head1 DESCRIPTION

A query that matches a document containing terms I<beginning> with the
given string.

=cut

use strict;
use warnings;
use base 'Plucene::Search::Query';
use Plucene::Search::BooleanQuery;
use Plucene::Search::TermQuery;

__PACKAGE__->mk_accessors(qw/ prefix reader /);

sub prepare { $_[0]->reader($_[1]) }

# This returns the underlying boolean query.

sub _query {
	my $self = shift;
	return $self->{query} if exists $self->{query};
	my $q      = new Plucene::Search::BooleanQuery;
	my $prefix = $self->prefix;
	my $enum   = $self->reader->terms($prefix);
	my ($field, $text) = ($prefix->field, $prefix->text);
	do {
		my $term = $enum->term;
		goto DONE
			unless $term
			and $term->text =~ /^\Q$text/
			and $term->field eq $field;
		my $tq = Plucene::Search::TermQuery->new({ term => $term });
		$tq->boost($self->boost);
		$q->add($tq, 0, 0);
	} while $enum->next;
	DONE: $self->{query} = $q;
}

=head2 to_string

	$q->to_string

Convert the query to a readable string format

=head2 sum_squared_weights

The sum sqaured weights of the query.

=head2 normalize

Normalize the query.

=cut

sub to_string {
	my ($self, $field) = @_;
	my $s = "";
	$s = $self->prefix->field . ":" if $self->prefix->field ne $field;
	$s .= $self->prefix->text . "*";
	$s .= "^" . $self->boost unless $self->boost == 1;
	$s;
}

sub sum_squared_weights { shift->_query->sum_squared_weights(@_) }
sub normalize           { shift->_query->normalize(@_) }
sub _scorer             { shift->_query->_scorer(@_) }

1;
