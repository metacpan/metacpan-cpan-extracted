
package Tangram::Type::Interval;

use base qw(Tangram::Type::Scalar);

$Tangram::Schema::TYPES{interval} = __PACKAGE__->new;

sub coldefs
{
    my ($self, $cols, $members, $schema) = @_;
    $self->_coldefs($cols, $members, 'INT', $schema);
}

1;
