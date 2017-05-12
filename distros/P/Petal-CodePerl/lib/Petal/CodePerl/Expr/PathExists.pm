use strict;
use warnings;

package Petal::CodePerl::Expr::PathExists;

use base qw( Code::Perl::Expr::Base );

use Class::MethodMaker (
	get_set => [qw( -java Expr )]
);

use Scalar::Util qw(blessed reftype );

sub eval
{
	my $self = shift;

	my $expr = $self->getExpr;
	eval {$expr->eval};

	return ! $@;
}

sub perl
{
	my $self = shift;

	my $expr_perl = $self->getExpr->perl;

	return qq{do{eval {$expr_perl}; ! \$@}};
}

1;
