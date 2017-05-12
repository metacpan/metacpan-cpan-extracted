# State::Machine Transition Failure Class
package State::Machine::Failure::Transition;

use Bubblegum::Class;
use Bubblegum::Constraints -typesof;

extends 'State::Machine::Failure';

our $VERSION = '0.07'; # VERSION

has transition_name => (
    is       => 'ro',
    isa      => typeof_string,
    required => 0
);

has transition_object => (
    is       => 'ro',
    isa      => typeof_object,
    required => 0
);

1;
