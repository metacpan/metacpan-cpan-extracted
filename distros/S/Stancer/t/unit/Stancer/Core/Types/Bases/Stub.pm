package Stancer::Core::Types::Bases::Stub;

use 5.020;
use strict;
use warnings;

use Moo;
use namespace::clean;

use Stancer::Core::Types::Bases qw(:all);
use Stancer::Core::Types::Helper qw(coerce_boolean);

has a_boolean => (
    is => 'ro',
    isa => Bool,
    coerce => coerce_boolean(),
);

has an_enumeration => (
    is => 'ro',
    isa => Enum['foo', 'bar'],
);

has a_string => (
    is => 'ro',
    isa => Str,
);

1;
