# $Header:$

use strict;
use warnings;

package Petal::CodePerl::Compiler;

use Code::Perl::Expr qw(:easy);
use Petal::CodePerl::Expr qw(:easy);

use Carp qw( confess );

use Data::Dumper qw(Dumper);

our $root = holder();

our $Parser;

sub compile
{
	my $self = shift;

	my $expr = shift;

	return $self->compileRule("only_expr", $expr);
}

sub compileRule
{
	require Petal::CodePerl::GrammarLoader;

	my $self = shift;

	my $rule = shift;

	my $expr = shift;

	my $expr_ref = ref($expr) ? $expr : \$expr;

	my $comp = $Parser->$rule($expr_ref);

	if (length($$expr_ref))
	{
		confess "'$$expr_ref' was left unparsed";
	}

	return $comp;
}

1;
