package Net::WAMP::Message::EVENT;

use strict;
use warnings;

use parent qw( Net::WAMP::Base::Message );

use constant PARTS => qw( Subscription  Publication  Auxiliary  Arguments  ArgumentsKw );

use constant HAS_AUXILIARY => 1;

use constant NUMERIC => qw( Subscription );

1;
