package Net::WAMP::Message::REGISTER;

use strict;
use warnings;

use parent qw( Net::WAMP::Base::SessionMessage );

use constant PARTS => qw( Request  Auxiliary  Procedure );

use constant HAS_AUXILIARY => 1;

1;
