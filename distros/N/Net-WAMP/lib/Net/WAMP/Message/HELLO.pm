package Net::WAMP::Message::HELLO;

use strict;
use warnings;

use parent qw( Net::WAMP::Base::Message );

use constant PARTS => qw( Realm  Auxiliary );

use constant HAS_AUXILIARY => 1;

1;
