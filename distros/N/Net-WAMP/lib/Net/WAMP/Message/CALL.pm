package Net::WAMP::Message::CALL;

use strict;
use warnings;

use parent qw(
    Net::WAMP::Base::SessionMessage
    Net::WAMP::Base::TowardCallee
);

use constant PARTS => qw( Request  Auxiliary  Procedure  Arguments  ArgumentsKw );

use constant HAS_AUXILIARY => 1;

1;
