package Net::WAMP::Message::REGISTERED;

use strict;
use warnings;

use parent qw( Net::WAMP::Base::Message );

use constant PARTS => qw( Request  Registration );

use constant NUMERIC => qw( Request );

1;
