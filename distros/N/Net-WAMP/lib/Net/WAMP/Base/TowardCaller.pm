package Net::WAMP::Base::TowardCaller;

use strict;
use warnings;

sub is_progress {
    return Types::Serialiser::is_true( $_[0]->get('Auxiliary')->{'progress'} );
}

1;
