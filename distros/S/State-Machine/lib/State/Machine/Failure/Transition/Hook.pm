# State::Machine::Transition Hook Failure Class
package State::Machine::Failure::Transition::Hook;

use Bubblegum::Class;
use Function::Parameters;

use Bubblegum::Constraints 'typeof_string';

extends 'State::Machine::Failure::Transition';

our $VERSION = '0.07'; # VERSION

has hook_name => (
    is       => 'ro',
    isa      => typeof_string,
    required => 0,
);

method _build_message {
    "Transition hooking failure."
}

1;
