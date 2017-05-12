package Net::WAMP::Message::PUBLISHED;

use strict;
use warnings;

use parent qw( Net::WAMP::Base::Message );

use constant PARTS => qw( Request  Publication );

use constant NUMERIC => qw( Request );

1;
