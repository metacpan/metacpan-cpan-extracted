package SomeRole;
our $VERSION = '0.03';

use Moose::Role;
use namespace::autoclean;

has foo => (
    is  => 'rw',
    isa => 'Str',
);

has bar => (
    is  => 'ro',
    isa => 'Int',
);

1;
