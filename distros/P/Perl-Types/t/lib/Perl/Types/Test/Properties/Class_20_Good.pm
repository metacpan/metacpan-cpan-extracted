# [[[ HEADER ]]]
package Perl::Types::Test::Properties::Class_20_Good;
use strict;
use warnings;
use types;
our $VERSION = 0.001_000;

# [[[ OO INHERITANCE ]]]
use parent qw(Perl::Types::Test);
use Perl::Types::Test;

# DEV NOTE, CORRELATION #rp054: auto-generation of OO property accessors/mutators checks the auto-generated Perl::Types type list for base data types to determine if the entire data structure can be returned by setting ($return_whole = 1)

# [[[ OO PROPERTIES ]]]
our hashref $properties = { test_property => my hashref::integer $TYPED_test_property = undef };  # no initial size, no initial values 

# [[[ SUBROUTINES & OO METHODS ]]]
sub test_method {
    { my hashref::integer $RETURN_TYPE };
    ( my Perl::Types::Test::Properties::Class_20_Good $self, my integer $input_integer ) = @ARG;
    my hashref::integer $test_property_shortcut = $self->get_test_property();
    $test_property_shortcut->{a} *= $input_integer;
    return $self->{test_property};
}

1;    # end of class
