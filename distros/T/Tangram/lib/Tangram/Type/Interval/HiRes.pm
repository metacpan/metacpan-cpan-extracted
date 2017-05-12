
package Tangram::Type::Interval;

use base qw(Tangram::Type::Scalar);

$Tangram::Schema::TYPES{interval_hires} = __PACKAGE__->new;

use Carp;
$Class::Tangram::defaults{interval_hires}
    = { check_func => sub {
	},
      };

sub coldefs
{
    my ($self, $cols, $members, $schema) = @_;
    $self->_coldefs($cols, $members, 'REAL', $schema);
}

1;
