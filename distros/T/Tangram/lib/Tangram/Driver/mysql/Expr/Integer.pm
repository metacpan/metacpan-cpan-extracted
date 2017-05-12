
package Tangram::Driver::mysql::Expr::Integer;

use strict;
use vars qw(@ISA);
 @ISA = qw( Tangram::Expr );

sub bitwise_and
{
	my ($self, $val) = @_;
	return Tangram::Type::Integer->expr("$self->{expr} & $val", $self->objects);
}

sub bitwise_nand
{
	my ($self, $val) = @_;
	return Tangram::Type::Integer->expr("~$self->{expr} & $val",
							 $self->objects);
}

sub bitwise_or
{
	my ($self, $val) = @_;
	return Tangram::Type::Integer->expr("$self->{expr} | $val", $self->objects);
}

sub bitwise_nor
{
	my ($self, $val) = @_;
	return Tangram::Type::Integer->expr("~$self->{expr} | $val", $self->objects);
}

1;
