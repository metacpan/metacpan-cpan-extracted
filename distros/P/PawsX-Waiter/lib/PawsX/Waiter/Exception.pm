package PawsX::Waiter::Exception;

use Moose;
extends 'Throwable::Error';

has name => (
    isa      => 'Str',
    is       => 'ro',
    required => 1
);

has reason => (
    isa      => 'Str',
    is       => 'ro',
    required => 1
);

has last_response => (
    is       => 'ro',
    required => 1
);

package PawsX::Exception::TimeOut;
use Moose;
extends 'PawsX::Waiter::Exception';

1;