package Net::WAMP::Message::INVOCATION;

use strict;
use warnings;

use parent qw(
    Net::WAMP::Base::SessionMessage
    Net::WAMP::Base::TowardCallee
);

use Types::Serialiser ();

use constant PARTS => qw( Request  Registration  Auxiliary  Arguments  ArgumentsKw );

use constant HAS_AUXILIARY => 1;

use constant NUMERIC => qw( Request Registration );

1;
