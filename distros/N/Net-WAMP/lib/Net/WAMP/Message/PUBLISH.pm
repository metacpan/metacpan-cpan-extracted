package Net::WAMP::Message::PUBLISH;

use strict;
use warnings;

use parent qw( Net::WAMP::Base::SessionMessage );

use Types::Serialiser ();

use constant PARTS => qw( Request  Auxiliary  Topic  Arguments  ArgumentsKw );

use constant HAS_AUXILIARY => 1;

sub publisher_wants_acknowledgement {
    return Types::Serialiser::is_true( $_[0]->get('Auxiliary')->{'acknowledge'} );
}

sub publisher_wants_to_be_excluded {
    return !Types::Serialiser::is_false( $_[0]->get('Auxiliary')->{'exclude_me'} );
}

1;
