package Net::WAMP::Message::UNSUBSCRIBE;

use strict;
use warnings;

use parent qw( Net::WAMP::Base::SessionMessage );

use constant PARTS => qw( Request  Subscription );

1;
