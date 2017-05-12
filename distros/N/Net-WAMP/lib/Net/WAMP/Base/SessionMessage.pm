package Net::WAMP::Base::SessionMessage;

use parent qw( Net::WAMP::Base::Message );

#As of the 19 March 2017 draft, all session ID fields are the same.
use constant SESSION_SCOPE_ID_ELEMENT => 'Request';

use constant NUMERIC => 'Request';

1;
