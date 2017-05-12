package Net::WAMP::Message::INTERRUPT;

use strict;
use warnings;

use parent qw( Net::WAMP::Base::Message );

use constant PARTS => qw( Request  Auxiliary );

use constant HAS_AUXILIARY => 1;

use constant NUMERIC => qw( Request );

1;
