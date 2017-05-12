
package Tangram::Type::Number;

use Tangram::Type::Scalar;
use strict;

use vars qw(@ISA);
 @ISA = qw( Tangram::Type::Scalar );

sub get_export_cols
{
    my ($self) = @_;
    return exists $self->{automatic} ? () : ($self->{col});
}

1;
