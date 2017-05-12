package Plucene::QueryParser;

use strict;
use warnings;

use base 'Class::Accessor::Fast';

use Carp 'croak';
use IO::Scalar;
use Text::Balanced qw(extract_delimited extract_bracketed);
our $DefaultOperator = "OR";

__PACKAGE__->mk_accessors(qw(analyzer default));

=head1 NAME

Plucene::QueryParser - Turn query strings into Plucene::Search::Query objects

=head1 SYNOPSIS

	my $p = Plucene::QueryParser->new({
		analyzer => Plucene::Analysis::Analyzer $a,
		default  => "text"
	});

	my Plucene::Search::Query $q = $p->parse("foo bar:baz");

=head1 DESCRIPTION

This module is responsible for turning a query string into a
Plucene::Query object. It needs to have an Analyzer object to help it
tokenize incoming queries, and it also needs to know the default field
to be used if no field is given in the query string.

=head1 METHODS

=head2 new

	my $p = Plucene::QueryParser->new({
		analyzer => Plucene::Analysis::Analyzer $a,
		default  => "text"
	});

Construct a new query parser

=cut

sub new {
	my $self = shift->SUPER::new(@_);
	croak "You need to pass an analyzer"
		unless UNIVERSAL::isa($self->{analyzer}, "Plucene::Analysis::Analyzer");
	croak "No default field name supplied!" unless $self->{default};
	return $self;
}

=head2 parse

	my Plucene::Search::Query $q = $p->parse("foo bar:baz");

Turns the string into a query object.

=cut

sub parse {
	my $self = shift;
	local $_ = shift;
	my $ast = shift;
	my @rv;
	while ($_) {
		s/^\s+// and next;
		my $item;
		$item->{conj} = "NONE";
		s/^(AND|OR|\|\|)\s+//i;
		if ($1) {
			$item->{conj} = uc $1;
			$item->{conj} = "OR"
				if $item->{conj} eq "||";
		}
		if (s/^\+//) { $item->{mods} = "REQ"; }
		elsif (s/^(-|!|NOT(?=[^\w:]))\s*//i) { $item->{mods} = "NOT"; }
		else { $item->{mods} = "NONE"; }

		if (s/^([^\s(":]+)://) { $item->{field} = $1 }

		# Subquery
		if (/^\(/) {
			my ($extracted, $remainer) = extract_bracketed($_, "(");
			if (!$extracted) { croak "Unbalanced subquery" }
			$_ = $remainer;
			$extracted =~ s/^\(//;
			$extracted =~ s/\)$//;
			$item->{query} = "SUBQUERY";
			$item->{subquery} = $self->parse($extracted, 1);
		} elsif (/^"/) {
			my ($extracted, $remainer) = extract_delimited($_, '"');
			if (!$extracted) { croak "Unbalanced phrase" }
			$_ = $remainer;
			$extracted =~ s/^"//;
			$extracted =~ s/"$//;
			$item->{query} = "PHRASE";
			$item->{term}  = $self->_tokenize($extracted);
		} elsif (s/^(\S+)\*//) {
			$item->{query} = "PREFIX";
			$item->{term}  = $self->_tokenize($1);
		} else {
			s/([^\s\^]+)// or croak "Malformed query";
			$item->{query} = "TERM";
			$item->{term}  = $self->_tokenize($1);
			if ($item->{term} =~ / /) { $item->{query} = "PHRASE"; }
		}
		s/^~(\d+)// and $item->{slop} = $1;
		if (s/^\^(\d+(?:.\d+)?)//) { $item->{boost} = $1 }

		push @rv, bless $item,
			"Plucene::QueryParser::" . ucfirst lc $item->{query};
	}
	my $obj = bless \@rv, "Plucene::QueryParser::TopLevel";

	# If we only want the AST, don't convert to a Search::Query.
	if ($ast) { return $obj }
	return $obj->to_plucene($self->{default});
}

sub _tokenize {
	my ($self, $image) = @_;
	my $stream = $self->{analyzer}->tokenstream(
		{
			field  => $self->{default},
			reader => IO::Scalar->new(\$image)
		}
	);
	my @words;
	while (my $x = $stream->next) { push @words, $x->text }
	join(" ", @words);
}

package Plucene::QueryParser::TopLevel;

sub to_plucene {
	my ($self, $field) = @_;
	return $self->[0]->to_plucene($field)
		if @$self == 1
		and $self->[0]->{mods} eq "NONE";

	my @clauses;
	$self->add_clause(\@clauses, $_, $field) for @$self;
	require Plucene::Search::BooleanQuery;
	my $query = new Plucene::Search::BooleanQuery;
	$query->add_clause($_) for @clauses;

	$query;
}

sub add_clause {
	my ($self, $clauses, $term, $field) = @_;
	my $q = $term->to_plucene($field);
	if ($term->{conj} eq "AND" and @$clauses) {

		# The previous term needs to become required
		$clauses->[-1]->required(1) unless $clauses->[-1]->prohibited;
	}

	if (  $Plucene::QueryParser::DefaultOperator eq "AND"
		and $term->{conj} eq "OR") {
		$clauses->[-1]->required(0) unless $clauses->[-1]->prohibited;
	}

	return unless $q;    # Shouldn't happen yet
	my $prohibited;
	my $required;
	if ($Plucene::QueryParser::DefaultOperator eq "OR") {

		# We set REQUIRED if we're introduced by AND or +; PROHIBITED if
		# introduced by NOT or -; make sure not to set both.
		$prohibited = ($term->{mods} eq "NOT");
		$required   = ($term->{mods} eq "REQ");

		$required = 1 if $term->{conj} eq "AND" and !$prohibited;
	} else {

		# We set PROHIBITED if we're introduced by NOT or -; We set
		# REQUIRED if not PROHIBITED and not introduced by OR
		$prohibited = ($term->{mods} eq "NOT");
		$required = (!$prohibited and $term->{conj} ne "OR");
	}
	require Plucene::Search::BooleanClause;
	push @$clauses,
		Plucene::Search::BooleanClause->new(
		{
			prohibited => $prohibited,
			required   => $required,
			query      => $q
		}
		);
}

package Plucene::QueryParser::Term;

sub to_plucene {
	require Plucene::Search::TermQuery;
	require Plucene::Index::Term;
	my ($self, $field) = @_;
	$self->set_term($field);
	my $q = Plucene::Search::TermQuery->new({ term => $self->{pl_term} });
	$self->set_boost($q);
	return $q;
}

sub set_term {
	my ($self, $field) = @_;
	$self->{pl_term} = Plucene::Index::Term->new(
		{
			field => (exists $self->{field} ? $self->{field} : $field),
			text => $self->{term}
		}
	);
}

sub set_boost {
	my ($self, $q) = @_;
	$q->boost($self->{boost}) if exists $self->{boost};
}

package Plucene::QueryParser::Phrase;
our @ISA = qw(Plucene::QueryParser::Term);

# This corresponds to the rules for "PHRASE" in the Plucene grammar

sub to_plucene {
	require Plucene::Search::PhraseQuery;
	require Plucene::Index::Term;
	my ($self, $field) = @_;
	my @words = split /\s+/, $self->{term};
	return $self->SUPER::to_plucene($field) if @words == 1;

	my $phrase = Plucene::Search::PhraseQuery->new;
	for my $word (@words) {
		my $term = Plucene::Index::Term->new(
			{
				field => (exists $self->{field} ? $self->{field} : $field),
				text => $word
			}
		);
		$phrase->add($term);
	}
	if (exists $self->{slop}) {
		$phrase->slop($self->{slop});
	}
	$self->set_boost($phrase);
	return $phrase;
}

package Plucene::QueryParser::Subquery;

sub to_plucene {
	my ($self, $field) = @_;
	$self->{subquery}
		->to_plucene(exists $self->{field} ? $self->{field} : $field);
}

package Plucene::QueryParser::Prefix;
our @ISA = qw(Plucene::QueryParser::Term);

sub to_plucene {
	require Plucene::Search::PrefixQuery;
	my ($self, $field) = @_;
	$self->set_term($field);
	my $q = Plucene::Search::PrefixQuery->new({ prefix => $self->{pl_term} });
	$self->set_boost($q);
	return $q;
}

1;
