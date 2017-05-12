# State::Machine::Simple Config Failure Class
package State::Machine::Failure::Simple;

use Bubblegum::Class;
use Function::Parameters;
use Bubblegum::Constraints -typesof;

extends 'State::Machine::Failure';

our $VERSION = '0.07'; # VERSION

has config => (
    is       => 'ro',
    isa      => typeof_arrayref,
    required => 1
);

1;
