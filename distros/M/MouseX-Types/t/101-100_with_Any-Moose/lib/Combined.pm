package Combined;

use strict;
use warnings;

use base Any::Moose 'X::Types::Combine';

__PACKAGE__->provide_types_from(qw/TestLibrary TestLibrary2/);

1;
