

use strict;

use Tangram::Type::Scalar;

package Tangram::Type::Time;

use vars qw(@ISA);
 @ISA = qw( Tangram::Type::String );

$Tangram::Schema::TYPES{rawtime} = Tangram::Type::Time->new;

sub coldefs
{
    my ($self, $cols, $members, $schema) = @_;
    $self->_coldefs($cols, $members, "TIME $schema->{sql}{default_null}");
}

1;
