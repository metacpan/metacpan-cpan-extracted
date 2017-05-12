package Net::WAMP::Message::SUBSCRIBED;

use strict;
use warnings;

use parent qw( Net::WAMP::Base::Message );

use constant PARTS => qw( Request  Subscription );

use constant NUMERIC => qw( Request );

1;
