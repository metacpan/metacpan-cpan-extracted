# State::Machine::Transition Missing Failure Class
package State::Machine::Failure::Transition::Missing;

use Bubblegum::Class;
use Function::Parameters;

extends 'State::Machine::Failure::Transition';

our $VERSION = '0.07'; # VERSION

method _build_message {
    "Transition missing."
}

1;
