package Container1;

use lib 't';

use Moo;
use MooX::Attributes::Shadow ':all';

use Contained;


has foo => (
    is      => 'ro',
    lazy    => 1,
    default => sub {
        Contained->new( xtract_attrs( 'Contained', shift ) );
    } );


sub run_shadow_attrs {

    shadow_attrs( Contained => @_ );
}

1;
