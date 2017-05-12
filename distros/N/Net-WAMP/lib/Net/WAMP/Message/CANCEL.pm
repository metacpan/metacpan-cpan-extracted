package Net::WAMP::Message::CANCEL;

use strict;
use warnings;

use parent qw( Net::WAMP::Base::Message );

use constant PARTS => qw( Request  Auxiliary );

use constant HAS_AUXILIARY => 1;

1;
