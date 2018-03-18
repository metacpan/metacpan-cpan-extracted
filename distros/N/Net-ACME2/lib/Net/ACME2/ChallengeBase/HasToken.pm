package Net::ACME2::ChallengeBase::HasToken;

use strict;
use warnings;

use parent 'Net::ACME2::Challenge';

use constant _ACCESSORS => (
    __PACKAGE__->_ACCESSORS(),
    'token',
);

1;
