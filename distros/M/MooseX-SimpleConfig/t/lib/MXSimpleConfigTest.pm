package MXSimpleConfigTestBase;
use Moose;

has 'inherited_ro_attr' => (is => 'ro', isa => 'Str');

no Moose;
1;

package MXSimpleConfigTest;
use Moose;
extends 'MXSimpleConfigTestBase';
with 'MooseX::SimpleConfig';

has 'direct_attr' => (is => 'ro', isa => 'Int');

has 'req_attr' => (is => 'rw', isa => 'Str', required => 1);

no Moose;
1;
