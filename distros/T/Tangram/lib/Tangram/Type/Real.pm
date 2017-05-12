
package Tangram::Type::Real;
use Tangram::Type::Number;
use strict;

use vars qw(@ISA);
 BEGIN { @ISA = qw( Tangram::Type::Number ); }

#use Class::ISA;
#use YAML;
#print YAML::Dump([Class::ISA::super_path(__PACKAGE__)]);

$Tangram::Schema::TYPES{real} = __PACKAGE__->new;

# XXX - not tested by test suite
sub coldefs
{
    my ($self, $cols, $members, $schema) = @_;
    $self->_coldefs($cols, $members, 'REAL', $schema);
}

1;
