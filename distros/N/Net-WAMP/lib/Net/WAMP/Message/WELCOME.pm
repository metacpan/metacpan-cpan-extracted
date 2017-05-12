package Net::WAMP::Message::WELCOME;

use strict;
use warnings;

use parent qw( Net::WAMP::Base::Message );

use constant PARTS => qw( Session  Auxiliary );

use constant HAS_AUXILIARY => 1;

use constant NUMERIC => qw( Session );

1;
