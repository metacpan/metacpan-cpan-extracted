package ObjectA;

use Moose;

has required => (is => 'ro', isa => 'Str', required => 1);
has optional => (is => 'ro', isa => 'Int' );
has semi_required => (is => 'ro', isa => 'Str' );
has simples => (is => 'ro');
has do_nothing => (is => 'ro', required => 0, isa => 'Maybe[Str]');

1;
