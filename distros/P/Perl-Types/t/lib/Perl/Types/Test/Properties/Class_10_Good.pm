# [[[ HEADER ]]]
use Perl::Types;
package Perl::Types::Test::Properties::Class_10_Good;
use strict;
use warnings;
our $VERSION = 0.001_000;

# [[[ OO INHERITANCE ]]]
use parent qw(Perl::Types::Test);
use Perl::Types::Test;

# DEV NOTE, CORRELATION #rp054: auto-generation of OO property accessors/mutators checks the auto-generated Perl::Types type list for base data types to determine if the entire data structure can be returned by setting ($return_whole = 1)

# [[[ OO PROPERTIES ]]]
our hashref $properties = { test_property => my arrayref::integer $TYPED_test_property = undef };  # no initial size, no initial values 

# [[[ SUBROUTINES & OO METHODS ]]]
sub test_method {
    { my arrayref::integer::method $RETURN_TYPE };
    ( my object $self, my integer $input_integer ) = @ARG;
    my arrayref::integer $test_property_shortcut = $self->get_test_property();
    $test_property_shortcut->[0] *= $input_integer;
    return $self->{test_property};
}

1;    # end of class
