
package Tangram::Driver::Sybase::Expr::Date;
use vars qw(@ISA);
 @ISA = qw( Tangram::Expr );

############################
# add method datepart($part)

sub datepart
{
	my ($self, $part) = @_; # $part is 'year', 'month', etc
	my $expr = $self->expr(); # the SQL string for this Expr

	##################################
	# build a new Expr of Integer type
	# pass this Expr's remote object list to the new Expr

	return Tangram::Type::Integer->expr("DATEPART($part, $expr)", $self->objects);
}

1;
