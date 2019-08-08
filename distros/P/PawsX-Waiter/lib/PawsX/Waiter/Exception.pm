package PawsX::Waiter::Exception;

use Moose;
extends 'Throwable::Error';

has last_response => (
    is       => 'ro',
    isa      => 'HashRef|Undef',
    required => 0
);

package PawsX::Waiter::Exception::TimeOut;
use Moose;
extends 'PawsX::Waiter::Exception';

1;
