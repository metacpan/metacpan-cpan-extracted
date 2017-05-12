package Net::WAMP::Message::GOODBYE;

use strict;
use warnings;

use parent qw( Net::WAMP::Base::Message );

use constant PARTS => qw( Auxiliary  Reason );

use constant HAS_AUXILIARY => 1;

1;
