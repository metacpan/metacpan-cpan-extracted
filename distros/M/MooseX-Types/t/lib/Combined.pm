package Combined;

use strict;
use warnings;

use base 'MooseX::Types::Combine';

__PACKAGE__->provide_types_from(qw/TestLibrary TestLibrary2/);

1;
