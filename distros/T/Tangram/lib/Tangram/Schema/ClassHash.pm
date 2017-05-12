package Tangram::Schema::ClassHash;
use strict;

use strict;
use Carp;

# XXX - not reached by test suite
sub class
{
   my ($self, $class) = @_;
   $self->{$class} or croak "unknown class '$class'";
}

1;
