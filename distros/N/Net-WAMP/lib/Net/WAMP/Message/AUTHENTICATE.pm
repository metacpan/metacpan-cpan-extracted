package Net::WAMP::Message::AUTHENTICATE;

use strict;
use warnings;

use parent qw( Net::WAMP::Base::Message );

use constant PARTS => qw( Signature  Extra );

1;
