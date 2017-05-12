
package Tangram::Type::String;

use Tangram::Type::Scalar;
use strict;

use vars qw(@ISA);
 @ISA = qw( Tangram::Type::Scalar );

$Tangram::Schema::TYPES{string} = __PACKAGE__->new;

sub literal
  {
    my ($self, $lit, $storage) = @_;
    return $storage->{db}->quote($lit);
}

sub coldefs
{
    my ($self, $cols, $members, $schema) = @_;
    $self->_coldefs($cols, $members, 'VARCHAR(255)', $schema);
}

1;



