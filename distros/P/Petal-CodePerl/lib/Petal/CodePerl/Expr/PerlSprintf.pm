use strict;
use warnings;

package Petal::CodePerl::Expr::PerlSprintf;

use base qw( Code::Perl::Expr::Base );

use Class::MethodMaker (
	get_set => [qw( -java Perl Params )]
);

sub eval
{
	my $self = shift;

	my @params = @{$self->getParams};

	my $perl_f = $self->getPerl;
	my $perl = sprintf($perl_f, map {$_->perl} @params);

	return eval $perl;
}

sub perl
{
	my $self = shift;

	my @params = @{$self->getParams};

	my $perl_f = $self->getPerl;

	my $perl = sprintf($perl_f, map {"(".$_->perl.")"} @params);
	
	return $perl;
}

1;
