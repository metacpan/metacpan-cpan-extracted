package Net::WAMP::Message::UNSUBSCRIBED;

use strict;
use warnings;

use parent qw( Net::WAMP::Base::Message );

use constant PARTS => qw( Request );

use constant NUMERIC => qw( Request );

1;
