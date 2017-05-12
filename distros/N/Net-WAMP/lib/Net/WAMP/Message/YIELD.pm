package Net::WAMP::Message::YIELD;

use strict;
use warnings;

use parent qw(
    Net::WAMP::Base::Message
    Net::WAMP::Base::TowardCaller
);

use Types::Serialiser ();

use constant PARTS => qw( Request  Auxiliary  Arguments  ArgumentsKw );

use constant HAS_AUXILIARY => 1;

use constant NUMERIC => qw( Request );

1;
