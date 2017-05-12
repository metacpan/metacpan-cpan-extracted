package Net::WAMP::Message::UNREGISTER;

use strict;
use warnings;

use parent qw( Net::WAMP::Base::SessionMessage );

use constant PARTS => qw( Request  Registration );

1;
