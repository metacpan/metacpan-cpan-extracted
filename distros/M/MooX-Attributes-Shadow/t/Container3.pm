package Container3;

use lib 't';

use Moo;
use MooX::Attributes::Shadow ':all';

use ContainedWRole;



has foo => (
    is      => 'ro',
    lazy    => 1,
    default => sub {
        ContainedWRole->new( ContainedWRole->xtract_attrs( shift ) );
    } );


sub run_shadow_attrs {

    ContainedWRole->shadow_attrs( @_ );
}

1;
